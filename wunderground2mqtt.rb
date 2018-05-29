#!/usr/bin/env ruby

require 'wunderground'
require 'mqtt'
require 'dotenv/load'
require 'json'
require 'pp'
require 'homebus'

Dotenv.load '.env.provision'

mqtt = { host: ENV['MQTT_HOSTNAME'],
         port: ENV['MQTT_PORT'],
         username: ENV['MQTT_USERNAME'],
         password: ENV['MQTT_PASSWORD'],
       }

uuid = ENV['UUID']

pp mqtt

if mqtt[:host].nil?
  puts 'host is nil'

  mqtt = HomeBus.provision(serial_number: '00-00-00-00',
                           manufacturer: 'Homebus',
                           model: 'Wunderground',
                           friendly_name: 'Wunderground',
                           pin: '',
                           devices: [ 
                                      {
                                        friendly_name: 'Wunderground temperature',
                                        friendly_location: 'Wunderground',
                                        update_frequency: 1000*60*5,
                                        accuracy: 10,
                                        precision: 100,
                                        wo_topics: [ 'temperature' ],
                                        ro_topics: [],
                                        rw_topics: []
                                      },
                                      {
                                        friendly_name: 'Wunderground humidity',
                                        friendly_location: 'Wunderground',
                                        update_frequency: 1000*60*5,
                                        accuracy: 10,
                                        precision: 100,
                                        wo_topics: [ 'humidity' ],
                                        ro_topics: [],
                                        rw_topics: []
                                      },
                                      {
                                        friendly_name: 'Wunderground pressure',
                                        friendly_location: 'Wunderground',
                                        update_frequency: 1000*60*5,
                                        accuracy: 10,
                                        precision: 100,
                                        wo_topics: [ 'pressure' ],
                                        ro_topics: [],
                                        rw_topics: []
                                      } ] )
                                                        

  unless mqtt
    abort 'MQTT provisioning failed'
  end

  pp mqtt

  uuid = mqtt[:uuid]
  mqtt.delete :uuid
end



wun = Wunderground.new ENV['WUNDERGROUND_API_KEY']

loop do
  results = wun.forecast_and_conditions_for ENV['WUNDERGROUND_LOCATION']

  puts results["current_observation"]["temp_f"]

  client = MQTT::Client.connect mqtt

  payload = {
    temp_f: results["current_observation"]['temp_f'],
    humidity: results["current_observation"]['relative_humidity'],
    pressure: results["current_observation"]['pressure_mb'],
    device_uuid: uuid
  }
  
  client.publish "environmental/weather", payload.to_json

  sleep(5*60)
end

# {"response"=>
#   {"version"=>"0.1",
#    "termsofService"=>"http://www.wunderground.com/weather/api/d/terms.html",
#    "features"=>{"forecast"=>1, "conditions"=>1}},
#  "current_observation"=>
#   {"image"=>
#     {"url"=>"http://icons.wxug.com/graphics/wu2/logo_130x80.png",
#      "title"=>"Weather Underground",
#      "link"=>"http://www.wunderground.com"},
#    "display_location"=>
#     {"full"=>"Portland, OR",
#      "city"=>"Portland",
#      "state"=>"OR",
#      "state_name"=>"Oregon",
#      "country"=>"US",
#      "country_iso3166"=>"US",
#      "zip"=>"97217",
#      "magic"=>"1",
#      "wmo"=>"99999",
#      "latitude"=>"45.56999969",
#      "longitude"=>"-122.69000244",
#      "elevation"=>"53.9"},
#    "observation_location"=>
#     {"full"=>"Vancouver, Oregon",
#      "city"=>"Vancouver",
#      "state"=>"Oregon",
#      "country"=>"US",
#      "country_iso3166"=>"US",
#      "latitude"=>"45.57",
#      "longitude"=>"-122.69",
#      "elevation"=>"200 ft"},
#    "estimated"=>{},
#    "station_id"=>"KORPORTL51",
#    "observation_time"=>"Last Updated on May 1, 7:02 AM PDT",
#    "observation_time_rfc822"=>"Tue, 01 May 2018 07:02:26 -0700",
#    "observation_epoch"=>"1525183346",
#    "local_time_rfc822"=>"Tue, 01 May 2018 07:02:42 -0700",
#    "local_epoch"=>"1525183362",
#    "local_tz_short"=>"PDT",
#    "local_tz_long"=>"America/Los_Angeles",
#    "local_tz_offset"=>"-0700",
#    "weather"=>"Overcast",
#    "temperature_string"=>"49.5 F (9.7 C)",
#    "temp_f"=>49.5,
#    "temp_c"=>9.7,
#    "relative_humidity"=>"90%",
#    "wind_string"=>"From the West at 2.0 MPH Gusting to 2.0 MPH",
#    "wind_dir"=>"West",
#    "wind_degrees"=>270,
#    "wind_mph"=>2.0,
#    "wind_gust_mph"=>"2.0",
#    "wind_kph"=>3.2,
#    "wind_gust_kph"=>"3.2",
#    "pressure_mb"=>"1019",
#    "pressure_in"=>"30.11",
#    "pressure_trend"=>"0",
#    "dewpoint_string"=>"47 F (8 C)",
#    "dewpoint_f"=>47,
#    "dewpoint_c"=>8,
#    "heat_index_string"=>"NA",
#    "heat_index_f"=>"NA",
#    "heat_index_c"=>"NA",
#    "windchill_string"=>"50 F (10 C)",
#    "windchill_f"=>"50",
#    "windchill_c"=>"10",
#    "feelslike_string"=>"50 F (10 C)",
#    "feelslike_f"=>"50",
#    "feelslike_c"=>"10",
#    "visibility_mi"=>"10.0",
#    "visibility_km"=>"16.1",
#    "solarradiation"=>"--",
#    "UV"=>"0",
#    "precip_1hr_string"=>"0.00 in ( 0 mm)",
#    "precip_1hr_in"=>"0.00",
#    "precip_1hr_metric"=>" 0",
#    "precip_today_string"=>"0.00 in (0 mm)",
#    "precip_today_in"=>"0.00",
#    "precip_today_metric"=>"0",
#    "icon"=>"cloudy",
#    "icon_url"=>"http://icons.wxug.com/i/c/k/cloudy.gif",
#    "forecast_url"=>"http://www.wunderground.com/US/OR/Portland.html",
#    "history_url"=>
#     "http://www.wunderground.com/weatherstation/WXDailyHistory.asp?ID=KORPORTL51",
#    "ob_url"=>
#     "http://www.wunderground.com/cgi-bin/findweather/getForecast?query=45.570999,-122.686996",
#    "nowcast"=>""},
#  "forecast"=>
#   {"txt_forecast"=>
#     {"date"=>"6:02 AM PDT",
#      "forecastday"=>
#       [{"period"=>0,
#         "icon"=>"cloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/cloudy.gif",
#         "title"=>"Tuesday",
#         "fcttext"=>
#          "Generally cloudy. Slight chance of a rain shower. High 63F. Winds light and variable.",
#         "fcttext_metric"=>
#          "Generally cloudy. Slight chance of a rain shower. High 17C. Winds light and variable.",
#         "pop"=>"20"},
#        {"period"=>1,
#         "icon"=>"nt_clear",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/nt_clear.gif",
#         "title"=>"Tuesday Night",
#         "fcttext"=>"A clear sky. Low near 45F. Winds light and variable.",
#         "fcttext_metric"=>"Mostly clear. Low 7C. Winds light and variable.",
#         "pop"=>"10"},
#        {"period"=>2,
#         "icon"=>"clear",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/clear.gif",
#         "title"=>"Wednesday",
#         "fcttext"=>"Abundant sunshine. High 76F. Winds NNW at 5 to 10 mph.",
#         "fcttext_metric"=>
#          "Mainly sunny. High around 25C. Winds light and variable.",
#         "pop"=>"10"},
#        {"period"=>3,
#         "icon"=>"nt_clear",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/nt_clear.gif",
#         "title"=>"Wednesday Night",
#         "fcttext"=>"Generally fair. Low around 50F. Winds light and variable.",
#         "fcttext_metric"=>
#          "Clear skies with a few passing clouds. Low 11C. Winds light and variable.",
#         "pop"=>"10"},
#        {"period"=>4,
#         "icon"=>"partlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/partlycloudy.gif",
#         "title"=>"Thursday",
#         "fcttext"=>
#          "Intervals of clouds and sunshine. High 77F. Winds SSW at 5 to 10 mph.",
#         "fcttext_metric"=>
#          "Intervals of clouds and sunshine. High around 25C. Winds SSW at 10 to 15 km/h.",
#         "pop"=>"10"},
#        {"period"=>5,
#         "icon"=>"nt_mostlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/nt_mostlycloudy.gif",
#         "title"=>"Thursday Night",
#         "fcttext"=>"Mainly cloudy. Low 48F. Winds WSW at 5 to 10 mph.",
#         "fcttext_metric"=>"Mainly cloudy. Low 9C. Winds SW at 10 to 15 km/h.",
#         "pop"=>"10"},
#        {"period"=>6,
#         "icon"=>"partlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/partlycloudy.gif",
#         "title"=>"Friday",
#         "fcttext"=>"Partly cloudy. High 74F. Winds light and variable.",
#         "fcttext_metric"=>"Partly cloudy. High 24C. Winds light and variable.",
#         "pop"=>"10"},
#        {"period"=>7,
#         "icon"=>"nt_partlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/nt_partlycloudy.gif",
#         "title"=>"Friday Night",
#         "fcttext"=>
#          "A few clouds from time to time. Low near 50F. Winds light and variable.",
#         "fcttext_metric"=>"A few clouds. Low 11C. Winds light and variable.",
#         "pop"=>"10"}]},
#    "simpleforecast"=>
#     {"forecastday"=>
#       [{"date"=>
#          {"epoch"=>"1525226400",
#           "pretty"=>"7:00 PM PDT on May 01, 2018",
#           "day"=>1,
#           "month"=>5,
#           "year"=>2018,
#           "yday"=>120,
#           "hour"=>19,
#           "min"=>"00",
#           "sec"=>0,
#           "isdst"=>"1",
#           "monthname"=>"May",
#           "monthname_short"=>"May",
#           "weekday_short"=>"Tue",
#           "weekday"=>"Tuesday",
#           "ampm"=>"PM",
#           "tz_short"=>"PDT",
#           "tz_long"=>"America/Los_Angeles"},
#         "period"=>1,
#         "high"=>{"fahrenheit"=>"63", "celsius"=>"17"},
#         "low"=>{"fahrenheit"=>"45", "celsius"=>"7"},
#         "conditions"=>"Overcast",
#         "icon"=>"cloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/cloudy.gif",
#         "skyicon"=>"",
#         "pop"=>20,
#         "qpf_allday"=>{"in"=>0.0, "mm"=>0},
#         "qpf_day"=>{"in"=>0.0, "mm"=>0},
#         "qpf_night"=>{"in"=>0.0, "mm"=>0},
#         "snow_allday"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_day"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_night"=>{"in"=>0.0, "cm"=>0.0},
#         "maxwind"=>{"mph"=>10, "kph"=>16, "dir"=>"NW", "degrees"=>321},
#         "avewind"=>{"mph"=>5, "kph"=>8, "dir"=>"NW", "degrees"=>321},
#         "avehumidity"=>65,
#         "maxhumidity"=>0,
#         "minhumidity"=>0},
#        {"date"=>
#          {"epoch"=>"1525312800",
#           "pretty"=>"7:00 PM PDT on May 02, 2018",
#           "day"=>2,
#           "month"=>5,
#           "year"=>2018,
#           "yday"=>121,
#           "hour"=>19,
#           "min"=>"00",
#           "sec"=>0,
#           "isdst"=>"1",
#           "monthname"=>"May",
#           "monthname_short"=>"May",
#           "weekday_short"=>"Wed",
#           "weekday"=>"Wednesday",
#           "ampm"=>"PM",
#           "tz_short"=>"PDT",
#           "tz_long"=>"America/Los_Angeles"},
#         "period"=>2,
#         "high"=>{"fahrenheit"=>"76", "celsius"=>"24"},
#         "low"=>{"fahrenheit"=>"50", "celsius"=>"10"},
#         "conditions"=>"Clear",
#         "icon"=>"clear",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/clear.gif",
#         "skyicon"=>"",
#         "pop"=>10,
#         "qpf_allday"=>{"in"=>0.0, "mm"=>0},
#         "qpf_day"=>{"in"=>0.0, "mm"=>0},
#         "qpf_night"=>{"in"=>0.0, "mm"=>0},
#         "snow_allday"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_day"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_night"=>{"in"=>0.0, "cm"=>0.0},
#         "maxwind"=>{"mph"=>10, "kph"=>16, "dir"=>"NNW", "degrees"=>346},
#         "avewind"=>{"mph"=>6, "kph"=>10, "dir"=>"NNW", "degrees"=>346},
#         "avehumidity"=>56,
#         "maxhumidity"=>0,
#         "minhumidity"=>0},
#        {"date"=>
#          {"epoch"=>"1525399200",
#           "pretty"=>"7:00 PM PDT on May 03, 2018",
#           "day"=>3,
#           "month"=>5,
#           "year"=>2018,
#           "yday"=>122,
#           "hour"=>19,
#           "min"=>"00",
#           "sec"=>0,
#           "isdst"=>"1",
#           "monthname"=>"May",
#           "monthname_short"=>"May",
#           "weekday_short"=>"Thu",
#           "weekday"=>"Thursday",
#           "ampm"=>"PM",
#           "tz_short"=>"PDT",
#           "tz_long"=>"America/Los_Angeles"},
#         "period"=>3,
#         "high"=>{"fahrenheit"=>"77", "celsius"=>"25"},
#         "low"=>{"fahrenheit"=>"48", "celsius"=>"9"},
#         "conditions"=>"Partly Cloudy",
#         "icon"=>"partlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/partlycloudy.gif",
#         "skyicon"=>"",
#         "pop"=>10,
#         "qpf_allday"=>{"in"=>0.0, "mm"=>0},
#         "qpf_day"=>{"in"=>0.0, "mm"=>0},
#         "qpf_night"=>{"in"=>0.0, "mm"=>0},
#         "snow_allday"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_day"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_night"=>{"in"=>0.0, "cm"=>0.0},
#         "maxwind"=>{"mph"=>10, "kph"=>16, "dir"=>"SSW", "degrees"=>199},
#         "avewind"=>{"mph"=>7, "kph"=>11, "dir"=>"SSW", "degrees"=>199},
#         "avehumidity"=>54,
#         "maxhumidity"=>0,
#         "minhumidity"=>0},
#        {"date"=>
#          {"epoch"=>"1525485600",
#           "pretty"=>"7:00 PM PDT on May 04, 2018",
#           "day"=>4,
#           "month"=>5,
#           "year"=>2018,
#           "yday"=>123,
#           "hour"=>19,
#           "min"=>"00",
#           "sec"=>0,
#           "isdst"=>"1",
#           "monthname"=>"May",
#           "monthname_short"=>"May",
#           "weekday_short"=>"Fri",
#           "weekday"=>"Friday",
#           "ampm"=>"PM",
#           "tz_short"=>"PDT",
#           "tz_long"=>"America/Los_Angeles"},
#         "period"=>4,
#         "high"=>{"fahrenheit"=>"74", "celsius"=>"23"},
#         "low"=>{"fahrenheit"=>"50", "celsius"=>"10"},
#         "conditions"=>"Partly Cloudy",
#         "icon"=>"partlycloudy",
#         "icon_url"=>"http://icons.wxug.com/i/c/k/partlycloudy.gif",
#         "skyicon"=>"",
#         "pop"=>10,
#         "qpf_allday"=>{"in"=>0.0, "mm"=>0},
#         "qpf_day"=>{"in"=>0.0, "mm"=>0},
#         "qpf_night"=>{"in"=>0.0, "mm"=>0},
#         "snow_allday"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_day"=>{"in"=>0.0, "cm"=>0.0},
#         "snow_night"=>{"in"=>0.0, "cm"=>0.0},
#         "maxwind"=>{"mph"=>10, "kph"=>16, "dir"=>"SW", "degrees"=>223},
#         "avewind"=>{"mph"=>5, "kph"=>8, "dir"=>"SW", "degrees"=>223},
#         "avehumidity"=>55,
#         "maxhumidity"=>0,
#         "minhumidity"=>0}]}}}
