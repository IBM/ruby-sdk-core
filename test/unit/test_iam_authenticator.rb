# frozen_string_literal: true

require("json")
require("jwt")
require_relative("./../test_helper.rb")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/basic_authenticator")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/config_based_authenticator_factory")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the base service
class IamAuthenticatorTest < Minitest::Test
  def test_iam_authenticator
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
      "access_token" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: {
          "apikey" => "apikey",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Connection" => "close",
          "Host" => "iam.cloud.ibm.com",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::IamAuthenticator.new(
      apikey: "apikey"
    )
    refute_nil(authenticator)
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
  end

  def test_iam_authenticator_client_id_client_secret
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
      "access_token" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: {
          "apikey" => "apikey",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Connection" => "close",
          "Authorization" => "Basic Yng6Yng=",
          "Host" => "iam.cloud.ibm.com",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::IamAuthenticator.new(
      apikey: "apikey",
      client_id: "bx",
      client_secret: "bx"
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
      "access_token" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: {
          "apikey" => "apikey",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Connection" => "close",
          "Host" => "iam.cloud.ibm.com",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::IamAuthenticator.new(
      apikey: "apikey"
    )
    refute_nil(authenticator)
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
    headers = {}
    authenticated_headers = { "Authorization" => "Bearer " + token }
    authenticator.authenticate(headers)
    assert_equal(headers, authenticated_headers)
  end

  def test_iam_authenticator_auth_url
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
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
      "access_token" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:post, "https://my.link/identity/token")
      .with(
        body: {
          "apikey" => "mesSi",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Connection" => "close",
          "Host" => "my.link",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::ConfigBasedAuthenticatorFactory.new.get_authenticator(service_name: "my_service")
    refute_nil(authenticator)
    assert_equal(authenticator.instance_variable_get(:@token_manager).access_token, token)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end
end
