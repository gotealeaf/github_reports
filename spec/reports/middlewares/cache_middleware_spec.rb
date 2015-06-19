require "faraday"
require "time"
require "reports/middleware/cache"
require "reports/storage/memory"

module Reports::Middleware
  RSpec.describe Cache do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }

    let(:conn) do
      Faraday.new do |builder|
        builder.use Cache, ::Reports::Storage::Memory.new
        builder.adapter :test, stubs
      end
    end

    it "returns a previously cached response" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'public max-age=60', 'Date' => Time.now.httpdate }, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(200)
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.test") { [200, {'Cache-Control' => 'public'}, "hello"] }
        conn.send(http_method, "http://example.test")
        stubs.send(http_method, "http://example.test") { [404, {}, "not found"] }

        response = conn.send(http_method, "http://example.test")
        expect(response.status).to eq(404)
      end
    end

    it "does not cache when the response doesn't have Cache-Controll header" do
      stubs.get("http://example.test") { [200, {}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "does not cache when the response Cache-Controll header has no-store value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-store'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "does not use cached response when the response Cache-Controll header has no-cache value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-store'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "does not use cached response when the response Cache-Controll header has no-cache value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-cache'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "does not use cached response when the response Cache-Controll header has must-validate value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'must-validate'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "uses cached response when it doesn't exceeds max age" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'max-age=60', 'Date' => Time.now.httpdate}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(200)
    end

    it "does not use cached response when it does exceeds max age" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'max-age=60', 'Date' => (Time.now - 2 * 60).httpdate }, "hello"] }

      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eq(404)
    end

    it "refetches a stale but current response and updates its date header" do
      # set up the cache for a response that's 2 minutes old
      two_minutes_ago = Time.now - 2 * 60
      cached_response_headers = { 'Cache-Control' => 'max-age=60', 'Date' => two_minutes_ago.httpdate, 'ETag' => 'oldETag' }
      stubs.get("http://example.test") { [200, cached_response_headers, "hello"] }
      conn.get("http://example.test")

      # server responds with 304 with empty body for subsequent requests if valid ETag is set
      now_time = Time.now
      response_headers = { 'Cache-Control' => 'max-age=60', 'Date' => now_time.httpdate, 'ETag' => 'oldEtag' }
      stubs.get("http://example.test") do |request_env|
        expect(request_env.request_headers["If-None-Match"]).to eq("oldETag")
        [304, response_headers, nil]
      end

      # the smart cache should return cached response with updated Date header

      response = conn.get("http://example.test")
      expect(response.headers["Date"]).to eq(now_time.httpdate)
      expect(response.body).to eq("hello")
      expect(response.headers["ETag"]).to eq("oldETag")
    end

    it "refetches a stale response and replaces it with a new one" do
      # set up the cache for a response that's 2 minutes old
      two_minutes_ago = Time.now - 2 * 60
      cached_response_headers = { 'Cache-Control' => 'max-age=60', 'Date' => two_minutes_ago.httpdate, 'ETag' => 'oldETag' }
      stubs.get("http://example.test") { [200, cached_response_headers, "hello"] }
      conn.get("http://example.test")

      # server responds with 200 with a new body for subsequent requestssince the resource has changed on the server side
      now_time = Time.now
      response_headers = { 'Cache-Control' => 'max-age=60', 'Date' => now_time.httpdate, 'ETag' => 'newETag' }
      stubs.get("http://example.test") do |request_env|
        expect(request_env.request_headers["If-None-Match"]).to eq("oldETag")
        [200, response_headers, "bye bye"]
      end

      # the smart cache should return cached response with updated Date header
      response = conn.get("http://example.test")
      expect(response.headers["Date"]).to eq(now_time.httpdate)
      expect(response.body).to eq("bye bye")
      expect(response.headers["ETag"]).to eq("newETag")
    end
  end
end
