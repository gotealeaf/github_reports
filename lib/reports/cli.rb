require 'rubygems'
require 'bundler/setup'

require 'thor'

require 'reports'

module Reports

  class CLI < Thor
    desc "repositories USERNAME", "Load the repo stats for USERNAME"
    option :forks, type: :boolean,
      desc: "Include forks in repo stats", default: false
    option :proxy, type: :boolean,
      desc: "Use an HTTP proxy running at localhost:8080", default: false
    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      api = GitHubAPI.new(proxy: options['proxy'])
      repos = api.repos_for_username(username, forks: options['forks'])

      puts "#{username} has #{repos.size} public repos.\n\n"

      table_printer = TablePrinter.new(STDOUT)

      repos.each do |repo|
        table_printer.print(repo.languages, title: repo.name, humanize: true)
        puts # blank line
      end

      stats = repos.inject(Hash.new(0)) do |sum, repo|
        repo.languages.each_pair do |language, bytes|
          sum[language] += bytes
        end
        sum
      end

      table_printer.print(stats, title: "Language Summary", humanize: true, total: true)
    end


    desc "activity USERNAME", "Summarize the activity of GitHub user USERNAME"
    option :proxy, type: :boolean,
      desc: "Use an HTTP proxy running at localhost:8080", default: false
    def activity(username)
      puts "Fetching activity summary for #{username}..."

      puts "Fetched 1 event.\n\n"

      table_printer = TablePrinter.new(STDOUT)

      sample_events = {PushEvent: 1}
      table_printer.print(sample_events, title: "Event Summary", total: true)

      sample_repos = {"username/repository" => 1 }
      puts # blank line
      table_printer.print(sample_repos, title: "Project Push Summary", total: true)
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    option :proxy, type: :boolean,
      desc: "Use an HTTP proxy running at localhost:8080", default: false
    def console
      Kernel.const_set :API, GitHubAPI.new(proxy: options['proxy'])
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end

end
