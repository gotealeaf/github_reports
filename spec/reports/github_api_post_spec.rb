require "spec_helper"

require "sinatra/base"
require "webmock/rspec"

require 'reports'

class FakeGitHub < Sinatra::Base
  attr_reader :gists

  def initialize
    super
    @gists = []
  end

  post '/gists' do
    content_type :json
    status 201
    @gists << JSON.parse(request.body.read)
    {html_url: "https://gist.github.com/username/abcdefg12345678"}.to_json
  end
end


module Reports
  RSpec.describe GitHubAPI do

    let(:fake_server) { FakeGitHub.new! }

    before(:each) do
      stub_request(:any, /api.github.com/).to_rack(fake_server)
    end

    it "creates a private gist" do
      api = GitHubAPI.new(ENV['GITHUB_TOKEN'])

      gist = api.create_private_gist("a quick gist", "hello.rb", "puts 'hello'")

      expect(gist.url).to eql("https://gist.github.com/username/abcdefg12345678")

      expect(fake_server.gists.first).to eql({
        "description" => "a quick gist",
        "public" => false,
        "files" => {
          "hello.rb" => {
            "content" => "puts 'hello'"
          }
        }
      })
    end

  end
end
