require 'logger'

module Reports
  module Middleware
    class Logging < Faraday::Middleware
      def initialize(app)
        super(app)
        @logger = logger
      end

      def call(env)
        start_time = Time.now

        @app.call(env).on_complete do
          duration = Time.now - start_time
          url, method, status = env.url.to_s, env.method, env.status
          @logger.debug '-> %s %s %d (%.3f s)' % [url, method.to_s.upcase, status, duration]
        end
      end

      def logger
        level = ENV["LOG_LEVEL"]
        logger = Logger.new(STDOUT)
        logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
        logger.level = Logger.const_get(level) if level
        logger
      end
    end
  end
end
