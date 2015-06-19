require 'rubygems'
require 'bundler/setup'
require 'thor'

require 'reports/github_api_client'
require 'reports/table_printer'

require 'dotenv'
Dotenv.load

module Reports

  class CLI < Thor

    desc "user_info USERNAME", "Get information for a user"
    def user_info(username)
      puts "Getting info for #{username}..."

      client = GitHubAPIClient.new()

      10.times { client.user_info(username) }
      info = client.user_info(username)

      puts "name: #{info.name}"
      puts "location: #{info.location}"
      puts "public repos: #{info.public_repos}"
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end


    desc "repositories USERNAME", "Load the repo stats for USERNAME"

    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      client = GitHubAPIClient.new
      repos = client.public_repos_for_user(username)

      puts "#{username} has #{repos.size} public repos.\n\n"
      repos.each { |repo| puts "#{repo.name} - #{repo.url}" }
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end
end
