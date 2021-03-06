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
require 'redis'
require 'friendly_id'

Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].sort.each do |path|
  require path
end

Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].sort.each do |path|
  require path
end

set :root, File.dirname(__FILE__)
set :bind, '0.0.0.0'
set :port, 80

# API routes
# Base uri is /api/guest
class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::ConfigFile
  config_file 'config/app_config.yml'

  set :nosql, settings.send(settings.environment.to_s)[:nosql]
  set :s3, settings.send(settings.environment.to_s)[:s3]
  set :consul, ConsulAgent::HTTP.new(settings.environment,
                                     settings.send(settings.environment.to_s))
  set :database, settings.consul[:mysql].merge(adapter: 'mysql2')
  set :show_exceptions, false unless settings.environment == :development

  configure do
    enable :cross_origin
  end

  before do
    # error 401 unless params[:api_key] == settings.consul[:api_key]
    response.headers['Access-Control-Allow-Origin'] = '*'
    content_type :json
  end

  error 401 do
    'wrong api key'
  end

  after do
    if response.body.is_a?(Hash)
      body Oj.dump response.body.merge('success' => true)
    else
      body Oj.dump('success' => false, 'result' => response.body)
    end
  end

  get '/' do
    'success!'
  end

  get '/drugs/:name/:section' do
    begin
      m = Medication.friendly.find(params[:name])
      m&.section(params[:section])
    rescue ActiveRecord::RecordNotFound
      'medication not found'
    end
  end

  get '/drug-classes' do
    { 'siteLinks' => HtmlSitemap.find_by_name('drug-classes')&.sitemap, 'header' => 'Drugs by Class' }
  end

  get '/drug-classes/*' do |path|
    { 'siteLinks' => HtmlSitemap.find_by_name('drug-classes')&.sitemap(path.split('/')), 'header' => path.tr('-', ' ').titleize }
  end

  get '/static-values' do
    {
      'numLivesSaved' => Healthtap::Api.num_lives_saved,
      'numAnswersServed' => Healthtap::Api.num_answers_served,
      'numDoctors' => Healthtap::Api.num_doctors,
      'success' => true
    }
  end

  options '*' do
    response.headers['Allow'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token'
    response.headers['Access-Control-Allow-Origin'] = '*'
    200
  end

  not_found do
    status 404
    'Not found'
  end
end
