require 'sinatra'
require 'json'

get '/' do
  'Hello World'
end

post '/new.?:format?' do
  data = JSON.parse request.body.read
end