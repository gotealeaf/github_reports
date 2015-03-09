require 'faraday'
require 'json'

module Reports

  Event = Struct.new(:type, :repo_name)
  Repo = Struct.new(:name, :languages)

  class GitHubAPI
    def initialize(token)
      @token = token
    end

    def public_events_for_user(username)
      url = "https://api.github.com/users/#{username}/events/public"
      events = []
      headers = {"Authorization" => "token #{@token}"}

      loop do
        response = Faraday.get(url, {}, headers)
        response_events = JSON.parse(response.body)
        events.concat(response_events)

        link_header = response.headers['link']
        break unless link_header

        next_page = link_header.split(',').find{|h| h =~ %r{rel="next"}}
        break unless next_page

        url = URI.extract(next_page).first
      end

      events.map do |event|
        Event.new(event["type"], event["repo"]["name"])
      end
    end

    def public_repos_for_user(username, options={})
      url = "https://api.github.com/users/#{username}/repos"
      repos = []
      headers = {"Authorization" => "token #{@token}"}

      loop do
        response = Faraday.get(url, {}, headers)
        response_repos = JSON.parse(response.body)
        repos.concat(response_repos)

        link_header = response.headers['link']
        break unless link_header

        next_page = link_header.split(',').find{|h| h =~ %r{rel="next"}}
        break unless next_page

        url = URI.extract(next_page).first
      end

      repos.map do |repo|
        next if !options[:forks] && repo["fork"]
        full_name = repo["full_name"]

        language_url = "https://api.github.com/repos/#{full_name}/languages"

        response = Faraday.get(language_url, {}, headers)
        languages = JSON.parse(response.body)

        Repo.new(repo["name"], languages)
      end.compact
    end

  end
end
