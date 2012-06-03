require 'sinatra'
require 'json'
require './elastic'

## Database (with globals for giggles) ##

$database = Elastic::Database.instance

## ROUTING ##

get '/' do
  'Hello World'
end

post '/:type/new' do
  data = JSON.parse request.body.read
  resp = $database.add_instance(params[:type], data['content'])
  resp.to_json
end