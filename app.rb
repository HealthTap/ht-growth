require 'json'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/config_file'
require 'aws-sdk-dynamodb'

Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].sort.each do |path|
  require path
end

Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].sort.each do |path|
  require path
end

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

  before do
    error 401 unless params[:key] == ENV['API_KEY']
    content_type :json
  end

  get '/medications/:name' do
    Medication.find_by_name(params[:name])&.overview
  end

  # TODO: Endpoints for writing medication data
end
