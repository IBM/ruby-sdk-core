# frozen_string_literal: true

require_relative("./../test_helper.rb")
require("jwt")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the JWT Token Manager
class JWTTokenManagerTest < Minitest::Test
  def test_request_token
    response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    token_manager = IBMCloudSdkCore::JWTTokenManager.new(
      CP4D_url: "https://the.sixth.one",
      username: "you",
      password: "me"
    )
    stub_request(:get, "https://the.sixth.one")
      .with(
        headers: {
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:request, method: "get", url: "https://the.sixth.one")
    assert_equal(response, token_response)
  end

  def test_request_token_fails
    token_manager = IBMCloudSdkCore::JWTTokenManager.new(
      url: "https://the.sixth.one",
      username: "you",
      password: "me"
    )
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:get, "https://the.sixth.one/")
      .with(
        headers: {
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    begin
      token_manager.send(:request, method: "get", url: "https://the.sixth.one")
    rescue IBMCloudSdkCore::ApiException => e
      assert(e.to_s.instance_of?(String))
    end
  end

  def test_request_token_not_expired
    access_token_layout = {
      "username" => "dummy",
      "role" => "Admin",
      "permissions" => %w[administrator manage_catalog],
      "sub" => "admin",
      "iss" => "sss",
      "aud" => "sss",
      "uid" => "sss",
      "iat" => Time.now.to_i,
      "exp" => Time.now.to_i + (6 * 3600)
    }
    access_token = JWT.encode(access_token_layout, "secret", "HS256", "kid": "230498151c214b788dd97f22b85410a5")

    token = {
      "accessToken" => access_token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => Time.now.to_i + (6 * 3600),
      "refresh_token" => "jy4gl91BQ"
    }

    token_manager = IBMCloudSdkCore::JWTTokenManager.new(
      CP4D_url: "https://the.sixth.one",
      username: "you",
      password: "me",
      token_name: "accessToken"
    )
    token_manager.send(:save_token_info, token_info: token)
    token_response = token_manager.send(:token)
    assert_equal(access_token, token_response)
  end

  def test_cp4d_disable_ssl
    token_layout = {
      "username": "dummy",
      "role": "Admin",
      "permissions": %w[administrator manage_catalog],
      "sub": "admin",
      "iss": "sss",
      "aud": "sss",
      "uid": "sss",
      "iat": Time.now.to_i + 3600,
      "exp": Time.now.to_i
    }
    token = JWT.encode token_layout, "secret", "HS256"
    response = {
      "accessToken" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:get, "https://icp.com/v1/preauth/validateAuth")
      .with(
        headers: {
          "Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ=",
          "Connection" => "close",
          "Host" => "icp.com",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::CloudPakForDataAuthenticator.new(
      username: "username",
      password: "password",
      url: "https://icp.com",
      disable_ssl_verification: true
    )
    IBMCloudSdkCore::BaseService.new(
      service_name: "assistant",
      service_url: "http://the.com",
      authenticator: authenticator
    )
    stub_request(:get, "http://the.com/music")
      .with(
        headers: {
          "Authorization" => "Basic Og==",
          "Host" => "the.com"
        }
      ).to_return(status: 200, body: {}.to_json, headers: {})
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
  end
end
