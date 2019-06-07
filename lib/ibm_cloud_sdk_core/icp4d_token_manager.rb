# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./version.rb")
require_relative("./jwt_token_manager")

module IBMCloudSdkCore
  # Class to manage ICP4D Token Authentication
  class ICP4DTokenManager < JWTTokenManager
    TOKEN_NAME = "accessToken"
    def initialize(url: nil, username: nil, password: nil, access_token: nil)
      raise ArgumentError.new("The url is mandatory for ICP4D.") if url.nil? && access_token.nil?

      url += "/v1/preauth/validateAuth"
      @username = username
      @password = password
      super(url: url, user_access_token: access_token, token_name: TOKEN_NAME)
    end

    def request_token
      request(
        method: "GET",
        url: @url,
        username: @username,
        password: @password
      )
    end
  end
end
