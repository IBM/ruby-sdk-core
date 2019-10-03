# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Basic Authenticator
  class BearerTokenAuthenticator < Authenticator
    attr_accessor :authentication_type
    def initialize(vars)
      defaults = {
        bearer_token: nil
      }
      vars = defaults.merge(vars)
      @bearer_token = vars[:bearer_token]
      @authentication_type = AUTH_TYPE_BEARER_TOKEN
      validate
    end

    # Adds the Authorization header, if possible
    def authenticate(headers)
      headers["Authorization"] = "Bearer #{@bearer_token}"
    end

    # Checks if all the inputs needed are present
    def validate
      raise ArgumentError.new("The bearer token shouldn\'t be None.") if @bearer_token.nil?
    end
  end
end
