require "reports"

module Reports

  RSpec.describe CacheMiddleware do

    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:storage) { {} }
    let(:response_array) { [200, {}, "hello"] }

    let(:conn) do
      Faraday.new do |builder|
        builder.use CacheMiddleware, storage: storage
        builder.adapter :test, stubs
      end
    end

    it "caches a response using its URL" do
      stubs.get("http://example.test") { response_array }

      conn.get "http://example.test"

      expect(storage["http://example.test"]).to be_instance_of(Faraday::Response)
    end

    it "returns a previously cached response" do
      stubs.get("http://example.test") { response_array }

      conn.get "http://example.test"

      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"

      expect(response.status).to eql(200)
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.test") { response_array }

        conn.send http_method, "http://example.test"

        expect(storage["http://example.test"]).to be_nil
      end
    end
  end
end
