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

        puts "Please setup your .netrc file at ~/.netrc using the directions here:"
        puts "https://github.com/octokit/octokit.rb#using-a-netrc-file"
        exit 1
      end
    end

    def create_default_client(use_proxy)
      #check_for_netrc

      octokit_client = Octokit::Client.new(netrc: true)

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
