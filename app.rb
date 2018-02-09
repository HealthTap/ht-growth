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

  set :environment, ENV['SINATRA_ENV'] || 'development'
  set :nosql, settings.send(settings.environment.to_s)[:nosql]
  set :s3, settings.send(settings.environment.to_s)[:s3]
  set :consul, ConsulAgent::HTTP.new(settings.environment,
                                     settings.send(settings.environment.to_s))
  set :database, settings.consul[:mysql].merge(adapter: 'mysql2')

  configure do
    enable :cross_origin
  end

  before do
    # error 401 unless params[:api_key] == 'fake_key_replace_later'
    response.headers['Access-Control-Allow-Origin'] = '*'
    content_type :json
  end

  after do
    if response.body.is_a?(Hash) || settings.environment == :development
      body Oj.dump response.body.merge('success' => true)
    else
      body Oj.dump('success' => false)
    end
  end

  get '/' do
    'success!'
  end

  get '/medications/:name/:section' do
    m = Medication.friendly.find(params[:name])
    m&.section(params[:section])
  end

  get '/drug-classes' do
    { 'siteLinks' => HtmlSitemap.find_by_name('drug-classes')&.sitemap }
  end

  get '/drug-classes/*' do |path|
    { 'siteLinks' => HtmlSitemap.find_by_name('drug-classes')&.sitemap(path.split('/')) }
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
end
