# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Basic Authenticator
  class BearerTokenAuthenticator < Authenticator
    @authentication_type = "bearerToken"

    attr_accessor :authentication_type
    def initialize(bearer_token: nil)
      @bearer_token = bearer_token
      validate
    end

    # Adds the Authorization header, if possible
    def authenticate(connector)
      connector.default_options.headers.add("Authorization", "Bearer #{@bearer_token}")
    end

    # Checks if all the inputs needed are present
    def validate
      raise ArgumentError.new("The bearer token shouldn\'t be None.") if @bearer_token.nil?
      raise ArgumentError.new('The bearer token shouldn\'t start or end with curly brackets or quotes. Be sure to remove any {} and \" characters surrounding your username') if check_bad_first_or_last_char(@username)
    end
  end
end
