module Reports
  class CacheMiddleware < Faraday::Middleware

    class HashStorage
      extend Forwardable
      def_delegator :@storage, :[], :get
      def_delegator :@storage, :[]=, :set
      def_delegators :@storage, :empty?

      def initialize
        @storage = {}
      end
    end

    class Response

      attr_reader :status
      attr_reader :key
      attr_reader :body
      attr_reader :response_headers

      def self.from_response(response)
        env = response.env.to_hash
        new(status: env[:status],
            body: env[:body],
            response_headers: env[:response_headers],
            key: cache_key(response.env))
      end

      def self.cache_key(env)
        env.url.to_s
      end

      def initialize(options={})
        @status = options[:status]
        @body = options[:body]
        @response_headers = options[:response_headers]
        @key = options[:key]
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
      @storage = options[:storage]
    end

    def call(env)
      key = Response.cache_key(env)

      if response_hash = @storage.get(key)
        response_hash[:response_headers]["X-Faraday-Cache-Status"] = "cached"
        return Response.new(response_hash).to_faraday_response
      end

      response = @app.call(env)
      if env.method == :get
        response.on_complete do
          cached = Response.from_response(response)
          @storage.set(cached.key, cached.to_hash)
        end
      end

      response
    end
  end
end
