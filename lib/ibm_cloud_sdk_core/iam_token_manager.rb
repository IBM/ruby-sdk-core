# frozen_string_literal: true

require("http")
require("json")
require("rbconfig")
require_relative("./version.rb")

module IBMCloudSdkCore
  # Class to manage IAM Token Authentication
  class IAMTokenManager
    DEFAULT_IAM_URL = "https://iam.cloud.ibm.com/identity/token"
    CONTENT_TYPE = "application/x-www-form-urlencoded"
    ACCEPT = "application/json"
    DEFAULT_AUTHORIZATION = "Basic Yng6Yng="
    DEFAULT_CLIENT_ID = "bx"
    DEFAULT_CLIENT_SECRET = "bx"
    REQUEST_TOKEN_GRANT_TYPE = "urn:ibm:params:oauth:grant-type:apikey"
    REQUEST_TOKEN_RESPONSE_TYPE = "cloud_iam"
    REFRESH_TOKEN_GRANT_TYPE = "refresh_token"

    attr_accessor :token_info, :user_access_token
    def initialize(iam_apikey: nil, iam_access_token: nil, iam_url: nil,
                   iam_client_id: nil, iam_client_secret: nil)
      @iam_apikey = iam_apikey
      @user_access_token = iam_access_token
      @iam_url = iam_url.nil? ? DEFAULT_IAM_URL : iam_url
      @token_info = {
        "access_token" => nil,
        "refresh_token" => nil,
        "token_type" => nil,
        "expires_in" => nil,
        "expiration" => nil
      }
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

    def request(method:, url:, headers: nil, params: nil, data: nil)
      response = nil
      if headers.key?("Content-Type") && headers["Content-Type"] == CONTENT_TYPE
        response = HTTP.basic_auth(user: @iam_client_id, pass: @iam_client_secret).request(
          method,
          url,
          body: HTTP::URI.form_encode(data),
          headers: headers,
          params: params
        )
      end
      return JSON.parse(response.body.to_s) if (200..299).cover?(response.code)

      require_relative("./api_exception.rb")
      raise ApiException.new(response: response)
    end

    # The source of the token is determined by the following logic:
    #   1. If user provides their own managed access token, assume it is valid and send it
    #   2. If this class is managing tokens and does not yet have one, make a request for one
    #   3. If this class is managing tokens and the token has expired refresh it. In case the refresh token is expired, get a new one
    # If this class is managing tokens and has a valid token stored, send it
    def token
      return @user_access_token unless @user_access_token.nil? || (@user_access_token.respond_to?(:empty?) && @user_access_token.empty?)

      if @token_info.all? { |_k, v| v.nil? }
        token_info = request_token
        save_token_info(
          token_info: token_info
        )
        return @token_info["access_token"]
      elsif token_expired?
        token_info = refresh_token_expired? ? request_token : refresh_token
        save_token_info(
          token_info: token_info
        )
        return @token_info["access_token"]
      else
        @token_info["access_token"]
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
        data: data
      )
      response
    end

    # Refresh an IAM token using a refresh token
    def refresh_token
      headers = {
        "Content-Type" => CONTENT_TYPE,
        "accept" => ACCEPT
      }
      data = {
        "grant_type" => REFRESH_TOKEN_GRANT_TYPE,
        "refresh_token" => @token_info["refresh_token"]
      }
      response = request(
        method: "POST",
        url: @iam_url,
        headers: headers,
        data: data
      )
      response
    end

    # Check if currently stored token is expired.
    # Using a buffer to prevent the edge case of the
    # token expiring before the request could be made.
    # The buffer will be a fraction of the total TTL. Using 80%.
    def token_expired?
      return true if @token_info["expiration"].nil? || @token_info["expires_in"].nil?

      fraction_of_ttl = 0.8
      time_to_live = @token_info["expires_in"].nil? ? 0 : @token_info["expires_in"]
      expire_time = @token_info["expiration"].nil? ? 0 : @token_info["expiration"]
      refresh_time = expire_time - (time_to_live * (1.0 - fraction_of_ttl))
      current_time = Time.now.to_i
      refresh_time < current_time
    end

    # Used as a fail-safe to prevent the condition of a refresh token expiring,
    # which could happen after around 30 days. This function will return true
    # if it has been at least 7 days and 1 hour since the last token was set
    def refresh_token_expired?
      return true if @token_info["expiration"].nil?

      seven_days = 7 * 24 * 3600
      current_time = Time.now.to_i
      new_token_time = @token_info["expiration"] + seven_days
      new_token_time < current_time
    end

    # Save the response from the IAM service request to the object's state
    def save_token_info(token_info:)
      @token_info = token_info
    end
  end
end
