# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("../token_managers/iam_token_manager.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Basic Authenticator
  class IamAuthenticator < Authenticator
    DEFAULT_CLIENT_ID = "bx"
    DEFAULT_CLIENT_SECRET = "bx"

    attr_accessor :authentication_type
    def initialize(vars)
      defaults = {
        url: nil,
        client_id: nil,
        client_secret: nil,
        disable_ssl_verification: nil
      }
      vars = defaults.merge(vars)
      @apikey = vars[:apikey]
      @url = vars[:url]
      @client_id = vars[:client_id]
      @client_secret = vars[:client_secret]
      @disable_ssl_verification = vars[:disable_ssl_verification]
      @authentication_type = AUTH_TYPE_IAM

      validate
      @token_manager = IAMTokenManager.new(
        apikey: @apikey,
        url: @url,
        client_id: @client_id,
        client_secret: @client_secret,
        disable_ssl_verification: @disable_ssl_verification
      )
    end

    def authenticate(headers)
      headers["Authorization"] = "Bearer #{@token_manager.access_token}"
      headers
    end

    def validate
      # Adds the Authorization header, if possible
      raise ArgumentError.new("The apikey shouldn\'t be None.") if @apikey.nil?
      raise ArgumentError.new('The apikey shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your apikey') if check_bad_first_or_last_char(@apikey)

      # Both the client id and secret should be provided or neither should be provided.
      if @client_id.nil? && @client_secret.nil?
        @client_id = DEFAULT_CLIENT_ID
        @client_secret = DEFAULT_CLIENT_SECRET
      elsif @client_id.nil? || client_secret.nil?
        raise ArgumentError.new("Only one of 'client_id' or 'client_secret' were specified, but both parameters should be specified together.")
      end
    end
  end
end
