# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Basic Authenticator
  class BasicAuthenticator < Authenticator
    attr_accessor :username, :password, :authentication_type
    def initialize(vars)
      defaults = {
        username: nil,
        password: nil
      }
      vars = defaults.merge(vars)
      @username = vars[:username]
      @password = vars[:password]
      @authentication_type = AUTH_TYPE_BASIC
      validate
    end

    # Adds the Authorization header, if possible
    def authenticate(headers)
      base64_authentication = Base64.strict_encode64("#{@username}:#{@password}")
      headers["Authorization"] = "Basic #{base64_authentication}"
    end

    # Checks if all the inputs needed are present
    def validate
      raise ArgumentError.new("The username and password shouldn\'t be None.") if @username.nil? || @password.nil?
      raise ArgumentError.new('The username shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your username') if check_bad_first_or_last_char(@username)
      raise ArgumentError.new('The password shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your password') if check_bad_first_or_last_char(@password)
    end
  end
end
