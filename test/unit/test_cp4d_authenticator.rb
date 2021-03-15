# frozen_string_literal: true

require("json")
require("jwt")
require_relative("./../test_helper.rb")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/basic_authenticator")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/config_based_authenticator_factory")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the base service
class Cp4dAuthenticatorTest < Minitest::Test
  def test_cp4d_authenticator
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
    refute_nil(authenticator)
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
  end

  def test_cp4d_authenticator_authenticate
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
    refute_nil(authenticator)
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
    headers = {}
    authenticated_headers = { "Authorization" => "Bearer " + token }
    authenticator.authenticate(headers)
    assert_equal(headers, authenticated_headers)
  end
end
