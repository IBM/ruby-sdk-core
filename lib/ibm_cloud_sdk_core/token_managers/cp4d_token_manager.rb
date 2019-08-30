# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./../version.rb")
require_relative("./jwt_token_manager")

module IBMCloudSdkCore
  # Class to manage CP4D Token Authentication
  class CP4DTokenManager < JWTTokenManager
    TOKEN_NAME = "accessToken"
    def initialize(url: nil, username: nil, password: nil, disable_ssl_verification: nil)
      raise ArgumentError.new("The url is mandatory for CP4D.") if url.nil?

      url += "/v1/preauth/validateAuth"
      @username = username
      @password = password
      @disable_ssl_verification = disable_ssl_verification
      super(url: url, token_name: TOKEN_NAME)
      token
    end

    def access_token
      @token_info[TOKEN_NAME]
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
