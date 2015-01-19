require 'vcr_helper'

require 'reports'

module Reports
  RSpec.describe GitHubAPI do

    it "can be instantiated" do
      GitHubAPI.new
    end

  end
end
