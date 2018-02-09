# Copied from HealthTap/next

require 'base64'
require 'json'
require 'httparty'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'

module ConsulAgent
  class HTTP
    include HTTParty

    DEFAULT_TIME_OUT = 5

    def initialize(env, yml_config = {})
      @standalone_keys = [:local, :grpc]
      @env = env
      @yml_config = yml_config
      @cache = {}
      @ttl = yml_config[:consul][:ttl] || 180
      self.class.base_uri yml_config[:consul][:uri]
    end

    def [](key, *nested)
      ok, result = get_from_cache(key)
      result = get_from_consul(key) unless ok

      return nil if result.nil?
      return result if nested.empty?
      return nil unless result.is_a?(Hash)
      result.dig(*nested)
    end

    def get_from_cache(key)
      return false unless @cache.key?(key)
      timestamp, value = @cache[key]
      return false if Time.now.to_i - timestamp > @ttl
      return true, value
    end

    def get_from_consul(key)
      result = nil

      default_key = @standalone_keys.include?(key) ? "/#{key}/default" : "/ht-growth/default/#{key}"
      env_key = @standalone_keys.include?(key) ? "/#{key}/#{@env}" : "/ht-growth/#{@env}/#{key}"

      [get_kv(default_key), get_kv(env_key), @yml_config[key]].each do |config|
        next if config.nil?
        result ||= HashWithIndifferentAccess.new({})
        if config.is_a?(Hash) && result.is_a?(Hash)
          result.deep_merge!(config)
        else
          result = config
        end
      end

      @cache[key] = [Time.now.to_i, result] unless result.nil?
      result
    end

    def get_kv(key)
      return nil if @env == 'test'
      resp = self.class.public_send(:get, "/kv#{key}")
      return nil unless resp.code < 300
      b64_config = JSON.parse(resp.body)[0]['Value']
      value = Base64.decode64(b64_config)
      begin
        HashWithIndifferentAccess.new(JSON.parse(value))
      rescue Exception
        value
      end
    rescue Errno::ECONNREFUSED => ex
      puts 'Not able to connect to Consul service. ' \
        'Please use the shared service by running ' \
        '"cp config/local_app_config.yml_sample config/local_app_config.yml"' if @env == 'development'
      raise ex
    end
  end
end
