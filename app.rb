require 'json'
require 'oj'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require 'activerecord-import'
require 'sinatra/config_file'
require 'aws-sdk-dynamodb'
require 'zlib'

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

# API routes
class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::ConfigFile

  config_file 'config/app_config.yml'
  set :consul_settings,
      ConsulAgent::HTTP.new(settings.environment,
                            settings.send(settings.environment.to_s))
  set :nosql, settings.send(settings.environment.to_s)[:nosql]

  configure do
    enable :cross_origin
  end
  
  before do
    # error 401 unless params[:api_key] == 'fake_key_replace_later'
    content_type :json
  end

  after do
    body Oj.dump response.body
  end

  get '/' do
    'success!'
  end

  get '/medications/:rxcui' do
    Medication.find_by_rxcui(params[:rxcui].to_i)&.overview
  end

  # Format { medication_name: [list of interaction objects] }
  # Interaction must have a ingredient_rxcui, interacts_with_rxcui and severity
  # May also have a rank, for display ordering purposes
  post '/medications/:rxcui/reset-interactions' do
    data = Oj.load request.body.read
    interactions_json.each do |rxcui, interactions_data|
      Medication.find_by_rxcui(rxcui.to_i)&.create_interactions(interactions_data)
    end
  end
end
