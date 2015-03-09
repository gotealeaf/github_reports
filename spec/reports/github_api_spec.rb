require 'vcr_helper'

require 'reports'

module Reports
  RSpec.describe GitHubAPI do

    it "fetches a user's public events", vcr: true do
      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])

      events = api.public_events_for_user("jim")

      expect(events.size).to eql(23)

      first_event = events.first

      expect(first_event).to be_an(Event)
      expect(first_event.type).to eql("PushEvent")
      expect(first_event.repo_name).to eql("jim/carmen")
    end

    it "fetches a user's public repositories", vcr: true do
      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])

      repos = api.public_repos_for_user("jim")

      expect(repos.size).to eql(24)

      first_repo = repos.first

      expect(first_repo).to be_a(Repo)
      expect(first_repo.name).to eql("alton")
      expect(first_repo.languages).to eql({"Ruby" => 19149})
    end

    it "fetches a user's public repositories, including forks", vcr: true do
      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])

      repos = api.public_repos_for_user("jim", forks: true)

      expect(repos.size).to eql(34)

      first_repo = repos.first

      expect(first_repo).to be_a(Repo)
      expect(first_repo.name).to eql("alton")
      expect(first_repo.languages).to eql({"Ruby" => 19149})
    end
  end
end
