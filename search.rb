require 'sinatra'
require 'json'
require './elastic'

## Database (with globals for giggles) ##

$database = Elastic::Database.instance
$database.add_index "user"
puts $database.indices

## ROUTING ##

get '/' do
  'Hello World'
end

post '/new.?:format?' do
  data = JSON.parse request.body.read
  resp = $database.index? data['type']
  resp.to_json
end