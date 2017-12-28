require 'json_schema'
require 'oj'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require 'activerecord-import'
require 'sinatra/config_file'
require 'aws-sdk-dynamodb'
require 'aws-sdk-s3'
require 'zlib'
require 'rack/cache'
require 'redis-rack-cache'

Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].sort.each do |path|
  require path
end

Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].sort.each do |path|
  require path
end

set :root, File.dirname(__FILE__)
set :bind, '0.0.0.0'
set :port, 80
set :database_file, './config/database.yml'

use Rack::Cache,
    metastore: 'redis://localhost:6379/0/metastore',
    entitystore: 'redis://localhost:6380/0/entitystore',
    verbose: true

# API routes
# Base uri is /api/guest
class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::ConfigFile

  config_file 'config/app_config.yml'
  set :consul_settings,
      ConsulAgent::HTTP.new(settings.environment,
                            settings.send(settings.environment.to_s))
  set :nosql, settings.send(settings.environment.to_s)[:nosql]
  set :s3, settings.send(settings.environment.to_s)[:s3]

  configure do
    enable :cross_origin
  end

  before do
    # error 401 unless params[:api_key] == 'fake_key_replace_later'
    response.headers['Access-Control-Allow-Origin'] = '*'
    content_type :json
  end

  after do
    body Oj.dump response.body
  end

  get '/' do
    'success!'
  end

  get '/medications/:name' do
    m = Medication.find_by_name(params[:name].tr('-', ' '))
    last_modified m.updated_at if m
    m&.overview
  end

  post '/medications/upload' do
    data = Oj.load request.body.read
    data = [data] unless data.is_a?(Array)
    data.each do |medication_data|
      rxcui = medication_data['rxcui']
      name = medication_data['name']
      m = Medication.find_or_create_by(rxcui: rxcui, name: name)
      m.upload_data(medication_data)
    end
    { result: true }
  end

  options "*" do
    response.headers["Allow"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response.headers["Access-Control-Allow-Origin"] = "*"
    200
  end
end
