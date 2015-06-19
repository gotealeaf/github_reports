require 'faraday'
require 'json'
require 'logger'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/status_check'
require_relative 'middleware/json_parsing'
require_relative 'middleware/cache'
require_relative 'storage/memory'

module Reports

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class AuthenticationFailure < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:name, :url)

  class GitHubAPIClient
    def user_info(username)
      url = "https://api.github.com/users/#{username}"

      response = connection.get(url)

      data = response.body

      if response.status == 200
        # puts "\nRate limit remaining: #{response.headers['X-RateLimit-Remaining']}\n\r"
        User.new(data["name"], data["location"], data["public_repos"])
      else
        raise NonexistentUser, "'#{username}' does not exist"
      end
    end

    def public_repos_for_user(username)
      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url)

      data = response.body

      if response.status == 200
        data.map {|repo_data| Repo.new(repo_data["full_name"], repo_data["url"])}
      else
        raise NonexistentUser, "'#{username}' does not exist"
      end
    end

    def connection
      @connection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::StatusCheck
        builder.use Middleware::Authentication
        builder.use Middleware::JSONParsing
        builder.use Middleware::Cache, Storage::Memory.new
        builder.use Middleware::Logging
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
