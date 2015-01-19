require 'reports/number_humanizer'

module Reports
  RSpec.describe NumberHumanizer do
    include NumberHumanizer

    it "humanizes a number" do
      expect(humanize_number(1024)).to eq("1 KB")
    end

    it "uses the abbreviation B for Bytes" do
      expect(humanize_number(13)).to eq("13 B")
    end

    it "uses the abbreviation B for Byte" do
      expect(humanize_number(1)).to eq("1 B")
    end
  end
end
