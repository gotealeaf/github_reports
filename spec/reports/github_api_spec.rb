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

  end
end
