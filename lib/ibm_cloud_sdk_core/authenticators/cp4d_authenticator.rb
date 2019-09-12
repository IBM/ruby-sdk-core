# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("../token_managers/cp4d_token_manager.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Basic Authenticator
  class CloudPakForDataAuthenticator < Authenticator
    attr_accessor :authentication_type, :disable_ssl_verification
    def initialize(vars)
      defaults = {
        username: nil,
        password: nil,
        url: nil,
        disable_ssl_verification: false
      }
      vars = defaults.merge(vars)
      @username = vars[:username]
      @password = vars[:password]
      @url = vars[:url]
      @disable_ssl_verification = vars[:disable_ssl_verification]
      @authentication_type = AUTH_TYPE_CP4D

      validate
      @token_manager = CP4DTokenManager.new(
        url: @url,
        username: @username,
        password: @password,
        disable_ssl_verification: @disable_ssl_verification
      )
    end

    # Adds the Authorization header, if possible
    def authenticate(headers)
      headers["Authorization"] = "Bearer #{@token_manager.access_token}"
    end

    # Checks if all the inputs needed are present
    def validate
      raise ArgumentError.new("The username or password shouldn\'t be None.") if @username.nil? || @password.nil?
      raise ArgumentError.new("The url shouldn\'t be None.") if @url.nil?
      raise ArgumentError.new('The username shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your username') if check_bad_first_or_last_char(@username)
      raise ArgumentError.new('The password shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your password') if check_bad_first_or_last_char(@password)
      raise ArgumentError.new('The url shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your url') if check_bad_first_or_last_char(@url)
    end
  end
end
