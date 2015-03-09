require 'rubygems'
require 'bundler/setup'

require 'thor'

require 'dotenv'
Dotenv.load

require 'reports'

module Reports

  class CLI < Thor
    desc "repositories USERNAME", "Load the repo stats for USERNAME"
    option :forks, type: :boolean,
      desc: "Include forks in repo stats", default: false

    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      api = GitHubAPI.new(ENV["GITHUB_TOKEN"])
      repos = api.public_repos_for_user(username, forks: options['forks'])

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
    end

    desc "activity USERNAME", "Summarize the activity of GitHub user USERNAME"
    def activity(username)
      puts "Fetching activity summary for #{username}..."

      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])
      events = api.public_events_for_user(username)
      puts "Fetched #{events.size} events.\n\n"

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

    desc "gist DESCRIPTION FILENAME CONTENTS", "Create a private Gist on GitHub"
    def gist(description, filename, contents)
      puts "Creating a private Gist..."

      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])
      gist = api.create_private_gist(description, filename, contents)

      puts "Your Gist is available at #{gist.url}."
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end

end
