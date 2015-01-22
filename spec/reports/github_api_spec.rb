require 'vcr_helper'

require 'reports'

module Reports
  RSpec.describe GitHubAPI do

    it "can be instantiated" do
      GitHubAPI.new
    end

    it "loads the repos for a username", vcr: true do
      api = GitHubAPI.new

      repos = api.repos_for_username('jim')

      expect(repos.size).to eq(24)
      expect(repos.map(&:name).sort).to eq([
        "alton", "backseat", "briefcase", "carmen",
        "carmen-demo-app", "carmen-rails", "diligence", "dollar_spec", "ds-slides",
        "fitzgerald", "gizmos", "interrogation", "is-it-live", "maths", "monk",
        "ocrunner", "prix-fixe", "recipes", "scribe", "sicp_solutions", "siesta",
        "summon", "toupee", "unshred"
      ])

      expect(repos[0].languages).to eq({Ruby: 19149})
    end

    it "loads all repos (including forks) for a username", vcr: true do
      api = GitHubAPI.new

      repos = api.repos_for_username('jim', forks: true)

      expect(repos.size).to eq(34)
      expect(repos.map(&:name).sort).to eq([
        "Polycode", "alton", "backseat", "briefcase", "carmen",
        "carmen-demo-app", "carmen-rails", "data", "diligence", "dollar_spec", "ds-slides",
        "fitzgerald", "gizmos", "heroku-buildpack-nodejs-grunt", "interrogation",
        "is-it-live", "jasminerice", "maths", "mongoid", "mongoid-site", "monk",
        "ocrunner", "prix-fixe", "recipes", "ruby-progressbar", "scribe",
        "sicp_solutions", "siesta", "simple_form", "sproutcore", "summon", "teaspoon",
        "toupee", "unshred"
      ])
    end

    it "fetches the events for a username", vcr: true do
      api = GitHubAPI.new

      events = api.public_events_for_username('jim')

      expect(events.size).to eq(45)
      expect(events.first).to be_instance_of(Event)
      expect(events.map{|e| [e.type, e.repo_name]}).to eq([
        ["CreateEvent", "jim/github_reports_template"],
        ["PushEvent", "jim/api_client_template"],
        ["PushEvent", "jim/api_client_template"],
        ["PushEvent", "jim/api_client_template"],
        ["CreateEvent", "jim/api_client_template"],
        ["CreateEvent", "jim/api_client_template"],
        ["PushEvent", "jim/carmen-rails"], ["PushEvent", "jim/carmen"],
        ["PushEvent", "jim/carmen-rails"], ["PushEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["PushEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["IssuesEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["IssuesEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["GollumEvent", "jim/carmen"], ["GollumEvent", "jim/carmen"],
        ["GollumEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PushEvent", "jim/carmen"], ["PullRequestEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"], ["IssueCommentEvent", "jim/carmen"],
        ["IssueCommentEvent", "jim/carmen"], ["PushEvent", "jim/carmen"],
        ["PullRequestEvent", "jim/carmen"]
      ])
    end

  end
end
