# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./version.rb")
require_relative("./jwt_token_manager")

module IBMCloudSdkCore
  # Class to manage IAM Token Authentication
  class IAMTokenManager < JWTTokenManager
    DEFAULT_IAM_URL = "https://iam.cloud.ibm.com/identity/token"
    CONTENT_TYPE = "application/x-www-form-urlencoded"
    ACCEPT = "application/json"
    DEFAULT_AUTHORIZATION = "Basic Yng6Yng="
    DEFAULT_CLIENT_ID = "bx"
    DEFAULT_CLIENT_SECRET = "bx"
    REQUEST_TOKEN_GRANT_TYPE = "urn:ibm:params:oauth:grant-type:apikey"
    REQUEST_TOKEN_RESPONSE_TYPE = "cloud_iam"
    TOKEN_NAME = "access_token"

    attr_accessor :token_info, :user_access_token
    def initialize(iam_apikey: nil, iam_access_token: nil, iam_url: nil,
                   iam_client_id: nil, iam_client_secret: nil)
      @iam_apikey = iam_apikey
      @user_access_token = iam_access_token
      @iam_url = iam_url.nil? ? DEFAULT_IAM_URL : iam_url
      super(url: iam_url, access_token: iam_access_token, token_name: TOKEN_NAME)

      # Both the client id and secret should be provided or neither should be provided.
      if !iam_client_id.nil? && !iam_client_secret.nil?
        @iam_client_id = iam_client_id
        @iam_client_secret = iam_client_secret
      elsif iam_client_id.nil? && iam_client_secret.nil?
        @iam_client_id = DEFAULT_CLIENT_ID
        @iam_client_secret = DEFAULT_CLIENT_SECRET
      else
        raise ArgumentError.new("Only one of 'iam_client_id' or 'iam_client_secret' were specified, but both parameters should be specified together.")
      end
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
        "apikey" => @iam_apikey,
        "response_type" => REQUEST_TOKEN_RESPONSE_TYPE
      }
      response = request(
        method: "POST",
        url: @iam_url,
        headers: headers,
        data: HTTP::URI.form_encode(data),
        username: @iam_client_id,
        password: @iam_client_secret
      )
      response
    end
  end
end
