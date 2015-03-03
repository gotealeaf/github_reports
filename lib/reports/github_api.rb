require 'faraday'
require 'json'

module Reports

  Event = Struct.new(:type, :repo_name)

  class GitHubAPI

    def public_events_for_user(username)
      url = "https://api.github.com/users/#{username}/events/public"
      response = Faraday.get(url)
      events = JSON.parse(response.body)
      events.map do |event|
        Event.new(event["type"], event["repo"]["name"])
      end
    end

  end
end
