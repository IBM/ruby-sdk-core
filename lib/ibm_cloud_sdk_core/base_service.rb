# frozen_string_literal: true

require("http")
require("rbconfig")
require("stringio")
require("json")
require_relative("./version.rb")
require_relative("./detailed_response.rb")
require_relative("./api_exception.rb")
require_relative("./utils.rb")
require_relative("./authenticators/authenticator")
require_relative("./authenticators/basic_authenticator")
require_relative("./authenticators/bearer_token_authenticator")
require_relative("./authenticators/config_based_authenticator_factory")
require_relative("./authenticators/iam_authenticator")
require_relative("./authenticators/cp4d_authenticator")
require_relative("./authenticators/no_auth_authenticator")

NORMALIZER = lambda do |uri| # Custom URI normalizer when using HTTP Client
  HTTP::URI.parse uri
end

module IBMCloudSdkCore
  # Class for interacting with the API
  class BaseService
    attr_accessor :service_name, :service_url
    attr_reader :conn, :authenticator, :disable_ssl_verification
    def initialize(vars)
      defaults = {
        authenticator: nil,
        disable_ssl_verification: false,
        service_name: nil
      }
      vars = defaults.merge(vars)
      @service_url = vars[:service_url]
      @authenticator = vars[:authenticator]
      @disable_ssl_verification = vars[:disable_ssl_verification]
      @service_name = vars[:service_name]

      raise ArgumentError.new("authenticator must be provided") if @authenticator.nil?

      @conn = HTTP::Client.new(
        headers: {}
      ).use normalize_uri: { normalizer: NORMALIZER }
      configure_service(@service_name)
      @temp_headers = {}
    end

    def disable_ssl_verification=(disable_ssl_verification)
      configure_http_client(disable_ssl_verification: disable_ssl_verification)
    end

    def add_default_headers(headers: {})
      raise TypeError unless headers.instance_of?(Hash)

      headers.each_pair { |k, v| @conn.default_options.headers.add(k, v) }
    end

    def configure_service(service_name)
      config = get_service_properties(service_name) if service_name

      @service_url = config[:url] unless config.nil? || config[:url].nil?
      disable_ssl_verification = explicitly_true(config[:disable_ssl]) unless config.nil? || config[:disable_ssl].nil?
      # configure the http client if ssl is disabled
      configure_http_client(disable_ssl_verification: disable_ssl_verification) if disable_ssl_verification
    end

    # @return [DetailedResponse]
    def request(args)
      defaults = { method: nil, url: nil, accept_json: false, headers: nil, params: nil, json: {}, data: nil }
      args = defaults.merge(args)
      args[:data].delete_if { |_k, v| v.nil? } if args[:data].instance_of?(Hash)
      args[:json] = args[:data].merge(args[:json]) if args[:data].respond_to?(:merge)
      args[:json] = args[:data] if args[:json].empty? || (args[:data].instance_of?(String) && !args[:data].empty?)
      args[:json].delete_if { |_k, v| v.nil? } if args[:json].instance_of?(Hash)
      args[:headers]["Accept"] = "application/json" if args[:accept_json] && args[:headers]["Accept"].nil?
      args[:headers]["Content-Type"] = "application/json" unless args[:headers].key?("Content-Type")
      args[:json] = args[:json].to_json if args[:json].instance_of?(Hash)
      args[:headers].delete_if { |_k, v| v.nil? } if args[:headers].instance_of?(Hash)
      args[:params].delete_if { |_k, v| v.nil? } if args[:params].instance_of?(Hash)
      args[:form].delete_if { |_k, v| v.nil? } if args.key?(:form)
      args.delete_if { |_, v| v.nil? }
      args[:headers].delete("Content-Type") if args.key?(:form) || args[:json].nil?

      conn = @conn

      @authenticator.authenticate(args[:headers])
      args[:headers] = args[:headers].merge(@temp_headers) unless @temp_headers.nil?
      @temp_headers = {} unless @temp_headers.nil?

      raise ArgumentError.new("service_url must be provided") if @service_url.nil?
      raise ArgumentError.new('The service_url shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your username') if check_bad_first_or_last_char(@service_url)

      if args.key?(:form)
        response = conn.follow.request(
          args[:method],
          HTTP::URI.parse(@service_url + args[:url]),
          headers: conn.default_options.headers.merge(HTTP::Headers.coerce(args[:headers])),
          params: args[:params],
          form: args[:form]
        )
      else
        response = conn.follow.request(
          args[:method],
          HTTP::URI.parse(@service_url + args[:url]),
          headers: conn.default_options.headers.merge(HTTP::Headers.coerce(args[:headers])),
          body: args[:json],
          params: args[:params]
        )
      end
      return DetailedResponse.new(response: response) if (200..299).cover?(response.code)

      raise ApiException.new(response: response)
    rescue OpenSSL::SSL::SSLError
      raise StandardError.new("The connection failed because the SSL certificate is not valid. To use a self-signed certificate, set the disable_ssl_verification parameter in configure_http_client.")
    end

    # @note Chainable
    # @param headers [Hash] Custom headers to be sent with the request
    # @return [self]
    def headers(headers)
      raise TypeError("Expected Hash type, received #{headers.class}") unless headers.instance_of?(Hash)

      @temp_headers = headers
      self
    end

    # @!method configure_http_client(proxy: {}, timeout: {}, disable_ssl_verification: false)
    # Sets the http client config, currently works with timeout and proxies
    # @param proxy [Hash] The hash of proxy configurations
    # @option proxy address [String] The address of the proxy
    # @option proxy port [Integer] The port of the proxy
    # @option proxy username [String] The username of the proxy, if authentication is needed
    # @option proxy password [String] The password of the proxy, if authentication is needed
    # @option proxy headers [Hash] The headers to be used with the proxy
    # @param timeout [Hash] The hash for configuring timeouts. `per_operation` has priority over `global`
    # @option timeout per_operation [Hash] Timeouts per operation. Requires `read`, `write`, `connect`
    # @option timeout global [Integer] Upper bound on total request time
    # @param disable_ssl_verification [Boolean] Disable the SSL verification (Note that this has serious security implications - only do this if you really mean to!)
    def configure_http_client(proxy: {}, timeout: {}, disable_ssl_verification: false)
      raise TypeError("proxy parameter must be a Hash") unless proxy.empty? || proxy.instance_of?(Hash)

      raise TypeError("timeout parameter must be a Hash") unless timeout.empty? || timeout.instance_of?(Hash)

      @disable_ssl_verification = disable_ssl_verification
      if disable_ssl_verification
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @conn.default_options = { ssl_context: ssl_context }
      end
      add_proxy(proxy) unless proxy.empty? || !proxy.dig(:address).is_a?(String) || !proxy.dig(:port).is_a?(Integer)
      add_timeout(timeout) unless timeout.empty? || (!timeout.key?(:per_operation) && !timeout.key?(:global))
    end

    private

    def add_timeout(timeout)
      if timeout.key?(:per_operation)
        raise TypeError("per_operation in timeout must be a Hash") unless timeout[:per_operation].instance_of?(Hash)

        defaults = {
          write: 0,
          connect: 0,
          read: 0
        }
        time = defaults.merge(timeout[:per_operation])
        @conn = @conn.timeout(write: time[:write], connect: time[:connect], read: time[:read])
      else
        raise TypeError("global in timeout must be an Integer") unless timeout[:global].is_a?(Integer)

        @conn = @conn.timeout(timeout[:global])
      end
    end

    def add_proxy(proxy)
      if (proxy[:username].nil? || proxy[:password].nil?) && proxy[:headers].nil?
        @conn = @conn.via(proxy[:address], proxy[:port])
      elsif !proxy[:username].nil? && !proxy[:password].nil? && proxy[:headers].nil?
        @conn = @conn.via(proxy[:address], proxy[:port], proxy[:username], proxy[:password])
      elsif !proxy[:headers].nil? && (proxy[:username].nil? || proxy[:password].nil?)
        @conn = @conn.via(proxy[:address], proxy[:port], proxy[:headers])
      else
        @conn = @conn.via(proxy[:address], proxy[:port], proxy[:username], proxy[:password], proxy[:headers])
      end
    end
  end
end
