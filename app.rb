require 'json'
require 'sinatra'
require 'sinatra/activerecord'

set :database_file, './config/database.yml'

# API routes
class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  before do
    content_type :json
  end

  get '/' do
    'Hello world!'
  end

  get '/test' do
    { hello: 'world' }.to_json
  end
end
