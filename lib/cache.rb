module Healthtap
  # Read and write object to redis
  class Cache
    QUESTION_PREFIX = 'guest-question-cache'.freeze
    QUESTION_TTL = 1.month
    STATIC_PREFIX = 'guest-static-cache'.freeze # Number lives saved, etc.
    STATIC_TTL = 1.hour
    @redis = nil

    def self.connection
      redis_settings = App.settings.consul[:redis]
      @redis = Redis.new(redis_settings) if @redis.nil?
      @redis
    end

    def self.read(key)
      val = connection.get(key)
      Oj.load(val) if val
    end

    def self.write(key, val)
      connection.set(key, Oj.dump(val))
    end

    def self.question_key(id)
      "#{QUESTION_PREFIX}-#{id}"
    end

    def self.static_key(k)
      "#{STATIC_PREFIX}-#{k}"
    end

    def self.read_question(id)
      read(question_key(id))
    end

    def self.write_question(id, val)
      write(question_key(id), val)
      connection.expire(question_key(id), QUESTION_TTL)
    end

    def self.read_static(k)
      read(static_key(k))
    end

    def self.write_static(k, val)
      write(static_key(k), val)
      connection.expire(static_key(k), STATIC_TTL)
    end
  end
end
