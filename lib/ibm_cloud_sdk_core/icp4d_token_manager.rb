# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./version.rb")
require_relative("./jwt_token_manager")

module IBMCloudSdkCore
  # Class to manage ICP4D Token Authentication
  class ICP4DTokenManager < JWTTokenManager
    def initialize(icp4d_url: nil, username: nil, password: nil, icp4d_access_token: nil)
      raise ArgumentError.new("`url` is a required parameter for Icp4dTokenManagerV1") if icp4d_url.nil?

      icp4d_url += "/v1/preauth/validateAuth"
      @username = username
      @password = password
      super(url: icp4d_url, user_access_token: icp4d_access_token)
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
