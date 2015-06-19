require 'vcr_helper'
require 'reports/github_api_client'

module Reports
  RSpec.describe GitHubAPIClient do
    describe "#user_info" do
      it "fetches info for a user", vcr: true do
        client = GitHubAPIClient.new

        info = client.user_info("octocat")

        expect(info.name).to eql("The Octocat")
        expect(info.location).to eql("San Francisco")
        expect(info.public_repos).to eql(5)
      end
    end
  end
end
