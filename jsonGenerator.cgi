#!/package/host/localhost/ruby-2.3.1/bin/ruby
require_relative 'Generate'

@errors = {}
@errorsWrap = {}
@cgi = CGI.new
@header = @cgi.header('type' => 'text/plain', 'Access-Control-Allow-Origin' => "*")

@element = @cgi["element"].gsub('ö','oe')
@start_date = @cgi["start_date"]
@end_date = @cgi["end_date"]
@sDate = Date.parse @start_date
@eDate = Date.parse @end_date
@now = Date.today
@zip = @cgi["location"]

@i = 0

@filePath = "/home/wetter/wetterDATA/"


#############################################################################################
############################### error handler
def throwError(kind, message)
  		@errors[kind] = message
  		@errorsWrap["errors"] = @errors
  		puts @header
  		puts @errorsWrap.to_json
end
#############################################################################################

#############################################################################################
############################### returns valid json, iterates through station stationarray if necessary or throws error
def jsonArrayFunc
	if !Dir.glob( @filePath + "sql/#{@sortedStationArray[@i].name}/#{@element}.db" ).empty? #check if database is on server
			jsonArray = @generate.generateJson(@sortedStationArray[@i]) #execute generateJson function from generate class
		if !jsonArray.empty? #if there is data to send -> return json
			puts @header
			puts jsonArray.to_json
		else #if there is the right database but not the right data in it try the next station
			@i = @i+1
			if @i<@sortedStationArray.count
				jsonArrayFunc()
			else #if there is still no data available -> throw error
				throwError("data", "no data")
  			end
		end
	else #if there is not the right database e.g. station number 399 don't have Niederschlagshöhe as database try the next station
		@i = @i+1
		if @i<@sortedStationArray.count
			jsonArrayFunc
		else #if there is still no data available -> throw error
			throwError("database", "no database")
		end
	end
end
#############################################################################################
############################### main program
def runMain
	if @eDate > (@now - 4) #check if the end date is before now - 4 days
		@eDate = @eDate-4 #if not, set end date - 4 days
		runMain()
	elsif (@start_date > @end_date) #check if the startdate is after enddate set startdate to enddate
		@start_date = @end_date
		runMain()
	else
		@generate = Generate.new(@filePath, @zip, @start_date, @end_date, @element) #create new Generate class
		zipRow = @generate.findZip(@zip)
		if zipRow == nil #check if it's a valid zip code
			throwError("location", "no valid zip code")
		elsif @end_date < "2000-01-01" #check if the end date is before earliest data
				@end_date = "2000-01-01"
			runMain()
		elsif @start_date < "2000-01-01" #check if the startdate is before earliest data
			@start_date = "2000-01-01"
			runMain()
		else
				lat, long = @generate.geo(zipRow)
				stationArray = @generate.selectInStationDB(lat, long)
			if stationArray.count < 1 #if there is no data available try the day before
				@eDate = @eDate - 1
				@end_date = (@eDate).to_s
				runMain()
			else
				@sortedStationArray = @generate.sortStationArray(stationArray, lat, long)
				jsonArrayFunc()
			end
		end
	end
end

runMain()
