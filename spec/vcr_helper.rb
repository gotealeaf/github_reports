require 'vcr'
require 'webmock'

require 'dotenv'
Dotenv.load

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true

  # Prevent GitHub credentials from being saved in the cassette files.
  c.filter_sensitive_data('<TOKEN>') { ENV['GITHUB_TOKEN'] }
end
