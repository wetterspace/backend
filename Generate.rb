require 'date'
require 'rubygems'
require 'cgi'
require 'json'
require 'sqlite3'
require 'ostruct'
require "csv"
require "haversine"

class Generate

	#############################################################################################
	# initialize class
	def initialize(filePath, location, start_date, end_date, element)
		@filePath = filePath
		@zip = location
		@start_date = start_date
		@end_date = end_date
		@element = element
	end
	#############################################################################################
	#############################################################################################
	# search zip code table for row with received zip
	def findZip(zipCode)
			zips = CSV.read(@filePath + "de_postal_codes.csv", col_sep: ",", encoding: "ISO8859-1")
			zipRow = zips.find {|row| row[0] == zipCode}
		return zipRow
	end #findZip end
	#############################################################################################
	#############################################################################################
	# extract geo coordinates from zip code
	def geo(zipRow)
			long = zipRow[6].to_f
			lat = zipRow[5].to_f
		return lat, long
	end
	#############################################################################################
	#############################################################################################
	# create new array with 250 stations around the zip code area, with weak sorting
	def selectInStationDB(lat, long)
			stationArray = Array.new()
			SQLite3::Database.open( @filePath + "stationDB.db" ) do |db|
		  		db.execute( "SELECT stationID, GeoBreite, GeoLaenge FROM stations as distance
		    		where #{@element.gsub(/\s+/, "").gsub('oe','ö')} = 1 
		    		and StartDate <= '#{@start_date}' and EndDate >= '#{@end_date}'
		    		ORDER BY ABS((#{lat} - GeoBreite)*(#{lat} - GeoBreite)) +
		    		ABS((#{long} - GeoLaenge)*(#{long} - GeoLaenge)) ASC LIMIT 250;" ) do |row|
		    		stationArray.insert(0, row)
		  		end
			end
		return stationArray
	end
	#############################################################################################
	#############################################################################################
	# sorting the station array exactly per distance
	def sortStationArray(stationArray, lat, long)
		sortedStationArray = Array.new()
			for i in 0..stationArray.count-1 # iterate through the station array
				stationStructure = OpenStruct.new
				stationStructure.name = stationArray[i][0] # reading the stationID of the station
				# reading the latitude and longitude of the station
				dbLat = (stationArray[i][1]).to_s.gsub(',', '.').to_f 
				dbLong = (stationArray[i][2]).to_s.gsub(',', '.').to_f
				# using the haversine formula to sort the stations precise
				stationStructure.distance = Haversine.distance(lat, long, dbLat, dbLong).to_km 
				sortedStationArray = sortedStationArray.insert(0, stationStructure).sort_by { |a| [a.distance] }
			end
		return sortedStationArray
	end
	#############################################################################################
	#############################################################################################
	# extracting the data from database and return array
	def generateJson(sortedStationArray)
		SQLite3::Database.open(@filePath + "sql/#{sortedStationArray.name}/#{@element}.db" ) do |db|
			  jsonArray = Array.new()
			# iterate through every row from start date to end date
			begin 
					 db.execute( "SELECT stationID, WERT, einheit, datum FROM data where datum >= '#{@start_date}' and datum <= '#{@end_date}';" ) do |row|
						# create array containing all requested data
						data = {}
						data["location"] = row[0].to_s
						data["wert"] = row[1]
						data["einheit"] = row[2]
						data["date"] = row[3]
						data["element"] = @element
						jsonArray.push(data)
					end
				return jsonArray
					rescue (SQLite3::SQLException)
				return []
			end
		end
	end
	#############################################################################################
	#############################################################################################
end

