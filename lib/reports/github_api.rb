require 'octokit'

module Reports
  class GitHubAPI
    def initialize(options={})
      options = options.symbolize_keys
      @client = options[:client] || create_default_client(options[:proxy])
    end

    private

    def check_for_netrc
      netrc_path = File.expand_path('~/.netrc')
      if !File.exist?(netrc_path) ||
         !File.read(netrc_path).include?('api.github.com')

        message = "Please setup your .netrc file at ~/.netrc using the directions here:" +
                  "https://github.com/octokit/octokit.rb#using-a-netrc-file"

        fail message
      end
    end

    def create_default_client(use_proxy)
      #check_for_netrc

      octokit_client = Octokit::Client.new

      if use_proxy
        puts "Using HTTP proxy..."
        ca_path = File.expand_path("~/.mitmproxy/mitmproxy-ca-cert.pem")
        options = { proxy: 'https://localhost:8080', ssl: {ca_file: ca_path}}
        octokit_client.connection_options = options
      end

      octokit_client.login

      octokit_client
    end
  end
end
