# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./../version.rb")
require_relative("./jwt_token_manager")

module IBMCloudSdkCore
  # Class to manage IAM Token Authentication
  class IAMTokenManager < JWTTokenManager
    DEFAULT_IAM_URL = "https://iam.cloud.ibm.com/identity/token"
    CONTENT_TYPE = "application/x-www-form-urlencoded"
    ACCEPT = "application/json"
    REQUEST_TOKEN_GRANT_TYPE = "urn:ibm:params:oauth:grant-type:apikey"
    REQUEST_TOKEN_RESPONSE_TYPE = "cloud_iam"
    TOKEN_NAME = "access_token"

    attr_accessor :token_info, :token_name, :client_id, :client_secret
    def initialize(
      apikey: nil,
      url: nil,
      client_id: nil,
      client_secret: nil,
      disable_ssl_verification: nil
    )
      @apikey = apikey
      url = DEFAULT_IAM_URL if url.nil?
      @client_id = client_id
      @client_secret = client_secret
      @disable_ssl_verification = disable_ssl_verification
      super(url: url, token_name: TOKEN_NAME)
      token
    end

    def access_token
      @token_info[TOKEN_NAME]
    end

    private

    # Request an IAM token using an API key
    def request_token
      headers = {
        "Content-Type" => CONTENT_TYPE,
        "Accept" => ACCEPT
      }
      data = {
        "grant_type" => REQUEST_TOKEN_GRANT_TYPE,
        "apikey" => @apikey,
        "response_type" => REQUEST_TOKEN_RESPONSE_TYPE
      }
      # @headers.add
      response = request(
        method: "POST",
        url: @url,
        headers: headers,
        data: HTTP::URI.form_encode(data),
        username: @client_id,
        password: @client_secret
      )
      response
    end
  end
end
