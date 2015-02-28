require 'vcr'
require 'webmock'
require 'netrc'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true

  # Prevent GitHub credentials from being saved in the cassette files.
  netrc = Netrc.read
  username, password = netrc["api.github.com"]
  c.filter_sensitive_data('<USER>') { username }
  c.filter_sensitive_data('<TOKEN>') { password }
end
