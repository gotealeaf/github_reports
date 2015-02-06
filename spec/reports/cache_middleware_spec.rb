require "pry-byebug"
require "reports"


module Reports

  RSpec.describe CacheMiddleware do

    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:storage) { CacheMiddleware::HashStorage.new }

    let(:conn) do
      Faraday.new do |builder|
        builder.use CacheMiddleware, storage: storage
        builder.adapter :test, stubs
      end
    end

    it "caches a response using its URL" do
      stubs.get("http://example.test") { [200, {}, "hello"] }

      conn.get "http://example.test"

      expect(storage.read("http://example.test")).to be_instance_of(Hash)
    end

    it "returns a previously cached response" do
      stubs.get("http://example.test") { [200, {}, "hello"] }

      responses = 2.times.map { conn.get "http://example.test" }

      expect(responses[0].headers["X-Faraday-Cache-Status"]).to be_nil
      expect(responses[1].headers["X-Faraday-Cache-Status"]).to eql("cached")
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.com") { [200, {}, "hello"] }

        conn.send http_method, "http://example.test"

        expect(storage.read("http://example.test")).to be_nil
      end
    end

    describe CacheMiddleware::Response do

      it "creates an instance from a Faraday::Response" do
        stubs.get("http://example.test") { [200, {"Server" => "gws"}, "hello"] }

        faraday_response = conn.get "http://example.test"
        response = CacheMiddleware::Response.from_response(faraday_response)

        expect(response.status).to eq(200)
        expect(response.body).to eq("hello")
        expect(response.response_headers).to eq({"Server" => "gws"})
      end

      it "converts itself to a hash" do
        response = CacheMiddleware::Response.new(
          status: 201,
          body: "<html>",
          response_headers: {
            "Server" => "thin"
          }
        )

        expect(response.to_hash).to eql(
          status: 201,
          body: "<html>",
          response_headers: {
            "Server" => "thin"
          }
        )
      end

      it "converts itself to a Faraday::Response" do
        response = CacheMiddleware::Response.new(
          status: 201,
          body: "<html>",
          response_headers: {
            "Server" => "thin",
          }
        )

        faraday_response = response.to_faraday_response

        expect(faraday_response.status).to eql(201)
        expect(faraday_response.body).to eq("<html>")
        expect(faraday_response.headers).to eq({"Server" => "thin"})
      end
    end

  end
end
