#!/package/host/localhost/ruby-2.3.1/bin/ruby

require 'rubygems'
require 'cgi'
require 'json'
require 'sqlite3'
require 'ostruct'
require "csv"
require "haversine"

############################### assoziative array for errors
errors = {}
errorsWrap = {}

############################### receive cgi data
cgi = CGI.new
header = cgi.header('type' => 'text/plain', 'Access-Control-Allow-Origin' => "*")
zip = cgi["location"]
start_date = cgi["start_date"]
end_date = cgi["end_date"]

element = "Relative Luftfeuchte".gsub('ö','oe')
medianCounter = 0


############################### zip code table
zips = CSV.read("/home/wetter/wetterDATA/de_postal_codes.csv", col_sep: ",", encoding: "ISO8859-1")
#plz = zips.find {|row| row[1] == stadt.capitalize.strip}

############################### search zip code table for row with received zip
zipRow = zips.find {|row| row[0] == zip}

############################### check if it's a valid zip code
if zipRow != nil

############################### read the longitude and latitude from csv file
long = zipRow[6].to_f
lat = zipRow[5].to_f

############################### create new array with 250 stations around the zip code area, with weak sorting
stationArray = Array.new()
SQLite3::Database.open( "/home/wetter/wetterDATA/stationDB.db" ) do |db|
  db.execute( "SELECT stationID, GeoBreite, GeoLaenge FROM stations as distance
    where #{element.gsub(/\s+/, "")} = 1 and StartDate <= '#{start_date}' and EndDate >= '#{end_date}'
    ORDER BY ABS((#{lat} - GeoBreite)*(#{lat} - GeoBreite)) +
    ABS((#{long} - GeoLaenge)*(#{long} - GeoLaenge)) ASC LIMIT 250;" ) do |row|
    stationArray.insert(0, row)
  end
end

############################### check the station Array
if !stationArray.empty?

############################### create new sorted array array
sortedStationArray = Array.new()

############################### iterate through the station array
for i in 0..stationArray.count-1

stationStructure = OpenStruct.new

############################### reading the stationID of the station
stationStructure.name = stationArray[i][0]

############################### reading the latitude and longitude of the station
dbLat = (stationArray[i][1]).to_s.gsub(',', '.').to_f
dbLong = (stationArray[i][2]).to_s.gsub(',', '.').to_f

############################### using the haversine formula to sort the stations precise
stationStructure.distance = Haversine.distance(lat, long, dbLat, dbLong).to_km
sortedStationArray = sortedStationArray.insert(0, stationStructure).sort_by { |a| [a.distance] }
end

############################### repeat if there is a median counter
for i in 0..medianCounter

############################### check if database is on server
if !Dir.glob( "/home/wetter/wetterDATA/sql/#{sortedStationArray[i].name}/#{element}.db" ).empty?


############################### open sqlite database in stationID folder and "element".db
SQLite3::Database.open( "/home/wetter/wetterDATA/sql/#{sortedStationArray[i].name}/#{element}.db" ) do |db|
  jsonArray = Array.new()

############################### iterate through every row from start date to end date
  db.execute( "SELECT stationID, WERT, einheit, datum FROM data where datum >= '#{start_date}' and datum <= '#{end_date}';" ) do |row|

############################### create array containing all requested data
data = {}
data["location"] = row[0].to_s
data["wert"] = row[1]
data["einheit"] = row[2]
data["date"] = row[3]
data["element"] = element

    jsonArray.push(data)
end #end of row loop
if !jsonArray.empty?
############################### puts header and json
puts header
puts jsonArray.to_json
else
  puts header
  errors["date"] = "date failure"
  errorsWrap["errors"] = errors
  puts errorsWrap.to_json
end
end #end of station iterate array
else 
  puts header
  errors["data"] = "no database"
  errorsWrap["errors"] = errors
  puts errorsWrap.to_json
end #end of database check
end #end of median loop
############################### throw exeption if there is no data
else
  puts header
  errors["data"] = "no data"
  errorsWrap["errors"] = errors
  puts errorsWrap.to_json
end #end of invalid date check
############################### throw exeption if the zip code is not valid
else
  puts header
  errors["location"] = "no valid zip code"
  errorsWrap["errors"] = errors
  puts errorsWrap.to_json

end #end of zip code check


################################ end of script