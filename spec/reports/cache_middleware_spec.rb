require "pry-byebug"
require "reports"


module Reports

  RSpec.describe CacheMiddleware do

    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:storage) { CacheMiddleware::HashStorage.new }
    let(:response_array) { [200, {}, "hello"] }

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

    it "returns a previously cached response when it is still fresh" do
      response_array[1]['Date'] = Time.new.httpdate
      response_array[1]['Cache-Control'] = "private; max-age=60"

      stubs.get("http://example.test") { response_array }

      responses = 2.times.map { conn.get "http://example.test" }

      expect(responses[0].headers["X-Faraday-Cache-Status"]).to be_nil
      expect(responses[1].headers["X-Faraday-Cache-Status"]).to eql("cached")
    end

    it "refetches a stale but current response and updates its date header" do
      now = Time.at(Time.new.to_i) # Truncate precision smaller than seconds
      now_date = now.httpdate
      url = "http://example.text"

      stale_response = CacheMiddleware::Response.new(
        status: 200,
        body: "old content",
        response_headers: { "Date" => (Time.new - 61).httpdate, "ETag" => "oldETag"})
      storage.write(url, stale_response.to_hash)

      stubs.get(url) do |env|
        expect(env.request_headers["If-None-Match"]).to eql("oldETag")
        [304, { "Date" => now_date, "ETag" => "oldETag" }, "" ]
      end

      response = conn.get url

      expect(response.status).to eql(200)
      expect(response.headers["Date"]).to eql(now_date)
      expect(response.body).to eql("old content")
      expect(response.headers["ETag"]).to eql("oldETag")

      stored_response_hash = storage.read(url)
      stored_response = CacheMiddleware::Response.new(stored_response_hash)

      expect(stored_response.time).to eq(now)
      expect(stored_response.status).to eql(200)
      expect(stored_response.body).to eql("old content")
      expect(stored_response.etag).to eql("oldETag")
    end

    it "refetches a stale response and replaces it with a new one" do
      now = Time.at(Time.new.to_i) # Truncate precision smaller than seconds
      now_date = now.httpdate
      url = "http://example.text"

      stale_response = CacheMiddleware::Response.new(
        status: 200,
        body: "old content",
        response_headers: { "Date" => (Time.new - 61).httpdate, "ETag" => "oldETag"})
      storage.write(url, stale_response.to_hash)

      stubs.get(url) do |env|
        expect(env.request_headers["If-None-Match"]).to eql("oldETag")
        [200, { "Date" => now_date, "ETag" => "newETag" }, "new content" ]
      end

      response = conn.get url

      expect(response.status).to eql(200)
      expect(response.headers["Date"]).to eql(now_date)
      expect(response.body).to eql("new content")
      expect(response.headers["ETag"]).to eql("newETag")

      stored_response_hash = storage.read(url)
      stored_response = CacheMiddleware::Response.new(stored_response_hash)

      expect(stored_response.time).to eq(now)
      expect(stored_response.status).to eql(200)
      expect(stored_response.body).to eql("new content")
      expect(stored_response.etag).to eql("newETag")
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.com") { [200, {}, "hello"] }

        conn.send http_method, "http://example.test"

        expect(storage.read("http://example.test")).to be_nil
      end
    end

    describe CacheMiddleware::Response do
      it "parses the Date header" do
        time = Time.new(2015, 2, 6, 10, 1, 4)

        response = CacheMiddleware::Response.new(response_headers: {
          'Date' => 'Fri, 06 Feb 2015 18:01:04 GMT'
        })
        expect(response.time).to eql(time)
      end

      it "calculates its age in seconds" do
        now = Time.new - 32
        response = CacheMiddleware::Response.new(response_headers: {
          'Date' => now.httpdate
        })

        expect(response.age).to eql(32)
      end

      it "has no time or age without a Date header" do
        response = CacheMiddleware::Response.new

        expect(response.time).to be_nil
        expect(response.age).to be_nil
      end

      it "parses a max-age out of the Cache-Control header" do
        response = CacheMiddleware::Response.new(response_headers: {
          "Cache-Control" => "private, max-age=60, s-maxage=60"
        })

        expect(response.max_age).to eql(60)
      end

      it "is stale when it is older than its max age" do
        one_minute_ago = Time.new - 61

        response = CacheMiddleware::Response.new(response_headers: {
          "Cache-Control" => "private, max-age=60, s-maxage=60",
          "Date" => one_minute_ago.httpdate
        })

        expect(response).to be_stale
      end

      it "is stale without a max_age" do
        response = CacheMiddleware::Response.new(response_headers: {
          "Date" => Time.new.httpdate
        })

        expect(response).to be_stale
      end

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
