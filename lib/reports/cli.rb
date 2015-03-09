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
      #puts "Fetching repository statistics for #{username}..."

      #puts "#{username} has 1 public repo.\n\n"

      #table_printer = TablePrinter.new(STDOUT)

      #sample_languages = {Ruby: 123, JavaScript: 23}
      #table_printer.print(sample_languages, title: "Sample Repo", humanize: true)

      #puts # blank line
      #table_printer.print(sample_languages, title: "Language Summary", humanize: true, total: true)
      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])
      puts api.public_repos_for_user(username, forks: options[:forks])
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

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    option :proxy, type: :boolean,
      desc: "Use an HTTP proxy running at localhost:8080", default: false
    def console
      #Kernel.const_set :API, GitHubAPI.new(proxy: options['proxy'])
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end

end
