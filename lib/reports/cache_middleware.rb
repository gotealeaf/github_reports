require 'redis'
require 'yaml'
require 'time'
require 'byebug'

module Reports
  class CacheMiddleware < Faraday::Middleware

    class HashStorage
      extend Forwardable
      def_delegator :@storage, :[], :read
      def_delegator :@storage, :[]=, :write

      def initialize
        @storage = {}
      end
    end

    class RedisStorage
      def initialize(redis=Redis.new)
        @redis = redis
      end
      def read(key)
        value = @redis.get(key)
        YAML.load(value) if value
      end
      def write(key, value)
        yaml = YAML.dump(value)
        @redis.set(key, yaml)
      end
    end

    class Response
      attr_reader :status
      attr_reader :body
      attr_reader :response_headers

      def self.from_response(response)
        env = response.env.to_hash
        new(status: env[:status],
            body: env[:body],
            response_headers: env[:response_headers])
      end

      def self.cache_key(env)
        env.url.to_s
      end

      def initialize(options={})
        @status = options[:status]
        @body = options[:body]
        @response_headers = options[:response_headers] || {}
      end

      def time
        date = @response_headers['Date']
        Time.httpdate(date) if date
      end

      def etag
        @response_headers['ETag']
      end

      def age
        (Time.now - time).floor if time
      end

      def stale?
        return true unless age && max_age # Always stale without these values
        age >= max_age
      end

      def max_age
        cache_control = @response_headers['Cache-Control']
        return nil unless cache_control
        match = cache_control.match(/max\-age=(\d+)/)
        match[1].to_i if match
      end

      def to_hash
        { status: @status, body: @body.dup, response_headers: @response_headers.dup }
      end

      def to_faraday_response
        Faraday::Response.new(to_hash)
      end
    end

    def initialize(app, options={})
      super(app)
      @storage = options[:storage] || HashStorage.new
    end

    def call(env)
      return @app.call(env) if env.method != :get

      key = Response.cache_key(env)

      if response_hash = @storage.read(key)
        response_hash[:response_headers]["X-Faraday-Cache-Status"] = "cached"
        cached_response = Response.new(response_hash)

        if cached_response.stale?
          @conditional_request = true
          etag = cached_response.etag
          env.request_headers['If-None-Match'] = etag
        else
          return cached_response.to_faraday_response
        end
      end

      response = @app.call(env)

      response.on_complete do |response_env|

        if @conditional_request && response.status == 304
          cached_hash = @storage.read(key)
          cached_response = Response.new(cached_hash)
          cached_response.response_headers['Date'] = response.headers['Date']

          @storage.write(key, cached_response.to_hash)
          response_env.update(cached_response.to_hash)
        else
          middleware_response = Response.from_response(response)
          @storage.write(key, middleware_response.to_hash)
        end
      end

      response
    end
  end
end
