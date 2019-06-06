# frozen_string_literal: true

require("http")
require("json")
require("jwt")
require("rbconfig")
require_relative("./version.rb")

TOKEN_NAME = "access_token"

module IBMCloudSdkCore
  # Class to manage JWT Token Authentication
  class JWTTokenManager
    def initialize(vars)
      defaults = {
        token_info: nil,
        url: nil,
        access_token: nil
      }
      vars = defaults.merge(vars)

      @url = vars[:url]
      @token_info = vars[:token_info]
      @user_access_token = vars[:access_token]
      @time_to_live = nil
      @expire_time = nil
      @disable_ssl_verification = false
    end

    def token
      if !@user_access_token.nil?
        @user_access_token
      elsif @token_info.nil? || token_expired?
        token_info = request_token
        save_token_info(token_info: token_info)
        @token_info[TOKEN_NAME]
      elsif !@token_info.nil?
        @token_info[TOKEN_NAME]
      end
    end

    def access_token(access_token)
      @user_access_token = access_token
    end

    private

    # Check if currently stored token is expired.
    # Using a buffer to prevent the edge case of the
    # token expiring before the request could be made.
    # The buffer will be a fraction of the total TTL. Using 80%.
    def token_expired?
      return true if @time_to_live.nil? || @expire_time.nil?

      fraction_of_ttl = 0.8
      refresh_time = @expire_time - (@time_to_live * (1.0 - fraction_of_ttl))
      current_time = Time.now.to_i
      refresh_time < current_time
    end

    def save_token_info(token_info: nil)
      access_token = token_info[TOKEN_NAME]
      decoded_response = JWT.decode access_token, nil, false, {}
      exp = decoded_response[0]["exp"]
      iat = decoded_response[0]["iat"]
      @time_to_live = exp - iat
      @expire_time = exp
      @token_info = token_info
    end

    def request(method:, url:, headers: nil, params: nil, data: nil, username: nil, password: nil)
      response = HTTP.basic_auth(user: username, pass: password).request(
        method,
        url,
        body: data,
        headers: headers,
        params: params
      )
      return JSON.parse(response.body.to_s) if (200..299).cover?(response.code)

      require_relative("./api_exception.rb")
      raise ApiException.new(response: response)
    end
  end
end
