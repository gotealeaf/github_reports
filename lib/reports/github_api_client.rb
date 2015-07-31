require 'faraday'
require 'logger'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/status_check'
require_relative 'middleware/json_parsing'

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

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = response.body
      User.new(data["name"], data["location"], data["public_repos"])
    end

    def public_repos_for_user(username)
      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url)

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = response.body
      data.map {|repo_data| Repo.new(repo_data["full_name"], repo_data["url"])}
    end

    def connection
      @connection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::JSONParsing
        builder.use Middleware::StatusCheck
        builder.use Middleware::Authentication
        builder.use Middleware::Logging
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
