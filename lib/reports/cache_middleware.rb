module Reports
  class CacheMiddleware < Faraday::Middleware

    def initialize(app, options={})
      super(app)
      @storage = options.fetch(:storage, {})
    end

    def call(env)
      key = env.url.to_s

      if response = @storage[key]
        return response
      end

      response = @app.call(env)

      if env.method == :get
        response.on_complete do
          @storage[key] = response
        end
      end

      response
    end
  end
end
