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

      client = GitHubAPIClient.new

      info = client.user_info(username)

      puts "name: #{info.name}"
      puts "location: #{info.location}"
      puts "public repos: #{info.public_repos}"
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end


    desc "repositories USERNAME", "Load the repo stats for USERNAME"
    option :forks, type: :boolean, desc: "Include forks in stats", default: false

    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      client = GitHubAPIClient.new
      repos = client.public_repos_for_user(username, forks: options[:forks])

      puts "#{username} has #{repos.size} public repos.\n\n"

      table_printer = TablePrinter.new(STDOUT)

      repos.each do |repo|
        table_printer.print(repo.languages, title: repo.name, humanize: true)
        puts # blank line
      end

      stats = Hash.new(0)
      repos.each do |repo|
        repo.languages.each_pair do |language, bytes|
          stats[language] += bytes
        end
      end

      table_printer.print(stats, title: "Language Summary", humanize: true, total: true)

    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "activity USERNAME", "Summarize the activity of GitHub user USERNAME"
    def activity(username)
      client = GitHubAPIClient.new
      events = client.public_events_for_user(username)
      puts "Fetched #{events.size} events.\n\n"

      print_activity_report(events)

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

    desc "gist DESCRIPTION FILENAME CONTENTS", "Create a private Gist on GitHub"
    def gist(description, filename, contents)
      puts "Creating a private Gist..."

      client = GitHubAPIClient.new
      gist_url = client.create_private_gist(description, filename, contents)

      puts "Your Gist is available at #{gist_url}."
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "star_repo FULL_REPO_NAME", "Star a repository"
    def star_repo(repo_name)
      puts "Starring #{repo_name}..."

      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        puts "You have already starred #{repo_name}."
      else
        client.star_repo(repo_name)
        puts "You have starred #{repo_name}."
      end
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "unstar_repo FULL_REPO_NAME", "Unstar a repository"
    def unstar_repo(repo_name)
      puts "Unstarring #{repo_name}..."

      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        client.unstar_repo(repo_name)
        puts "You have unstarred #{repo_name}."
      else
        puts "You have not starred #{repo_name}."
      end
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    private

    def print_activity_report(events)
      table_printer = TablePrinter.new(STDOUT)
      event_types_map = events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.type] += 1
      end

      table_printer.print(event_types_map, title: "Event Summary", total: true)
      push_events = events.select { |event| event.type == "PushEvent" }
      push_events_map = push_events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.repo_name] += 1
      end

      puts # blank line
      table_printer.print(push_events_map, title: "Project Push Summary", total: true)
    end
  end
end
