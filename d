[1mdiff --git a/jsonGenerator.cgi b/jsonGenerator.cgi[m
[1mindex 58126f1..85f1ec1 100644[m
[1m--- a/jsonGenerator.cgi[m
[1m+++ b/jsonGenerator.cgi[m
[36m@@ -8,8 +8,13 @@[m [mrequire 'ostruct'[m
 require "csv"[m
 require "haversine"[m
 [m
[31m-############################### receive cgi data [m
[32m+[m[32m############################### assoziative array for errors[m
[32m+[m[32merrors = {}[m
[32m+[m[32merrorsWrap = {}[m
[32m+[m
[32m+[m[32m############################### receive cgi data[m
 cgi = CGI.new[m
[32m+[m[32mheader = cgi.header('type' => 'text/plain', 'Access-Control-Allow-Origin' => "*")[m
 zip = cgi["location"][m
 start_date = cgi["start_date"][m
 end_date = cgi["end_date"][m
[36m@@ -18,7 +23,7 @@[m [melement = "Relative Luftfeuchte"[m
 medianCounter = 0[m
 [m
 [m
[31m-############################### zip code table [m
[32m+[m[32m############################### zip code table[m
 zips = CSV.read("/home/wetter/wetterDATA/de_postal_codes.csv", col_sep: ",", encoding: "ISO8859-1")[m
 #plz = zips.find {|row| row[1] == stadt.capitalize.strip}[m
 [m
[36m@@ -28,23 +33,23 @@[m [mzipRow = zips.find {|row| row[0] == zip}[m
 ############################### check if it's a valid zip code[m
 if zipRow != nil[m
 [m
[31m-############################### read the longitude and latitude from csv file [m
[32m+[m[32m############################### read the longitude and latitude from csv file[m
 long = zipRow[6].to_f[m
 lat = zipRow[5].to_f[m
 [m
[31m-############################### create new array with 250 stations around the zip code area, with weak sorting [m
[32m+[m[32m############################### create new array with 250 stations around the zip code area, with weak sorting[m
 stationArray = Array.new()[m
 SQLite3::Database.open( "/home/wetter/wetterDATA/stationDB.db" ) do |db|[m
[31m-  db.execute( "SELECT stationID, GeoBreite, GeoLaenge FROM stations as distance [m
[31m-  	where #{element.gsub(/\s+/, "")} = 1 and StartDate <= '#{start_date}' and EndDate >= '#{end_date}' [m
[31m-  	ORDER BY ABS((#{lat} - GeoBreite)*(#{lat} - GeoBreite)) + [m
[32m+[m[32m  db.execute( "SELECT stationID, GeoBreite, GeoLaenge FROM stations as distance[m
[32m+[m[41m  [m	[32mwhere #{element.gsub(/\s+/, "")} = 1 and StartDate <= '#{start_date}' and EndDate >= '#{end_date}'[m
[32m+[m[41m  [m	[32mORDER BY ABS((#{lat} - GeoBreite)*(#{lat} - GeoBreite)) +[m
   	ABS((#{long} - GeoLaenge)*(#{long} - GeoLaenge)) ASC LIMIT 250;" ) do |row|[m
     stationArray.insert(0, row)[m
   end[m
 end[m
 [m
 ############################### check the station Array[m
[31m-if stationArray.count > 1[m
[32m+[m[32mif !stationArray.empty?[m
 [m
 ############################### create new sorted array array[m
 sortedStationArray = Array.new()[m
[36m@@ -61,7 +66,7 @@[m [mstationStructure.name = stationArray[i][0][m
 dbLat = (stationArray[i][1]).to_s.gsub(',', '.').to_f[m
 dbLong = (stationArray[i][2]).to_s.gsub(',', '.').to_f[m
 [m
[31m-############################### using the haversine formula to sort the stations precise  [m
[32m+[m[32m############################### using the haversine formula to sort the stations precise[m
 stationStructure.distance = Haversine.distance(lat, long, dbLat, dbLong).to_km[m
 sortedStationArray = sortedStationArray.insert(0, stationStructure).sort_by { |a| [a.distance] }[m
 end[m
[36m@@ -73,7 +78,7 @@[m [mfor i in 0..medianCounter[m
 if !Dir.glob( "/home/wetter/wetterDATA/sql/#{sortedStationArray[i].name}/#{element}.db" ).empty?[m
 end[m
 [m
[31m-############################### open sqlite database in stationID folder and "element".db [m
[32m+[m[32m############################### open sqlite database in stationID folder and "element".db[m
 SQLite3::Database.open( "/home/wetter/wetterDATA/sql/#{sortedStationArray[i].name}/#{element}.db" ) do |db|[m
   jsonArray = Array.new()[m
 [m
[36m@@ -88,21 +93,35 @@[m [mdata["einheit"] = row[2][m
 data["date"] = row[3][m
 data["element"] = element[m
 