require 'httparty'
require 'csv'


APP_NAME = 'Crime Address Lookup by /u/codeman869'
KEY = File.open("../key","r").read
ONEDAY = 86400
PAUSE = 1/3
@dailyCounter = 0
@rowCounter = 0
@resumeRow = File.exists?("resume") ? File.open("resume", "r").read.to_i : 0
@double_failure = false



class Google
  include HTTParty
  base_uri 'https://maps.googleapis.com'
  format :json
  headers "User-agent" => APP_NAME
end



def getLatLong(id, date, time, offense, address)
  #get the response
  response = Google.get("/maps/api/geocode/json", :query => {:key=>KEY, :address=>address} )
  #add to daily counter to limit requests to 2500 per day
  @dailyCounter += 1

  
  if response["status"] == "OVER_QUERY_LIMIT" #we hit our quota limit without realizing
    #Hit the daily quota, must wait 24 hours
    #Check to see if requesting too many per second
    unless @double_failure
      puts "Hit the daily quota, reached row: #{@rowCounter}, pausing 5 seconds and then resuming"
      @double_failure = true
      sleep(5)
      getLatLong(id,date,time,offense,address)
    else
      #actually hit the quota limit for the day
      @double_failure = false
      puts "Hit the daily quota after trying twice, writing to file."
      f = File.open("resume", "w+")
      f.write(@rowCounter-1)
      f.close
      mustSleep(ONEDAY)
    end
      
    
    
  elsif @dailyCounter >= 2500 && response["status"] == "OK" #hit our limit but was still good with google, log it and sleep
    @double_failure = false
    puts "Reaching the daily limit, reached row #{@rowCounter}"
     CSV.open("addresses.csv", "a+") do |csv|
       lat = response["results"][0]["geometry"]["location"]["lat"]
       long = response["results"][0]["geometry"]["location"]["lng"]
       response_address = response["results"][0]["formatted_address"]
      
       csv << [id, @rowCounter, date, time, offense, address, response_address, lat, long]
       puts "Added to address.csv: \n\t%s: \n\tLat:%s Long:%s" % [address, lat, long]
       f = File.open("resume", "w+")
       f.write(@rowCounter)
       f.close
     end
    mustSleep(ONEDAY)
  elsif response["status"] == "OK" #otherwise write to file
    @double_failure = false
     CSV.open("addresses.csv", "a+") do |csv|
       lat = response["results"][0]["geometry"]["location"]["lat"]
       long = response["results"][0]["geometry"]["location"]["lng"]
       response_address = response["results"][0]["formatted_address"]
      
       csv << [id, @rowCounter, date, time, offense, address, response_address, lat, long]
       puts "Added to address.csv: \n\t%s: \n\tLat:%s Long:%s" % [address, lat, long]
     end
      mustSleep(PAUSE)
      
    else
       #unknown error, log it, sleep 5
      puts "Error: #{response["status"]}"
      mustSleep(5)
      CSV.open("errors.csv", "a+") do |csv|
        csv << [id, date, time, offense, address]  
        
      end
      
  end
  
  
end

def mustSleep(time)
  puts "Mandatory sleep for #{time} seconds"
  
  sleep(time)
  if time == ONEDAY
    @dailyCounter = 0
  end
end



CSV.foreach("crime_incident_data.csv") do |row|
  if @rowCounter != 0 && @rowCounter > @resumeRow
    puts "Getting Lat/Long for: #{row[4]}"
    getLatLong(row[0],row[1],row[2],row[3],row[4])
  end
  @rowCounter += 1
end





