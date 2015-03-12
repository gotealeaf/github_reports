require 'active_support/notifications'

module Reports
  class LoggingMiddleware < Faraday::Middleware
    def call(env)
      ActiveSupport::Notifications.instrument("request.faraday", env) do
        @app.call(env)
      end
    end
  end
end
