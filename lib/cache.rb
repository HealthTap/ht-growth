module Healthtap
  # Read and write object to redis
  class Cache
    QUESTION_PREFIX = 'guest-question'.freeze
    @redis = nil

    def self.connection
      @redis = Redis.new if @redis.nil?
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

    def self.read_question(id)
      read(question_key(id))
    end

    def self.write_question(id, val)
      write(question_key(id), val)
    end

  end
end
