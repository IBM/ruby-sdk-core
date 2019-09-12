# frozen_string_literal: true

require_relative("./../test_helper.rb")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the IAM Token Manager
class IAMTokenManagerTest < Minitest::Test
  def test_request_token
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
        body: { "apikey" => "apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    # Use default iam_url, client id/secret
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      apikey: "apikey",
      url: "https://iam.cloud.ibm.com/identity/token",
      client_id: "bx",
      client_secret: "bx"
    )
    token_response = token_manager.send(:request_token)
    assert_equal(response, token_response)
  end

  def test_request_token_fails
    iam_url = "https://iam.cloud.ibm.com/identity/token"
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    assert_raises do
      IBMCloudSdkCore::IAMTokenManager.new(
        apikey: "apikey",
        url: iam_url
      )
    end
  end

  def test_request_token_fails_catch_exception
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 401, body: response.to_json, headers: {})
    begin
      IBMCloudSdkCore::IAMTokenManager.new(
        apikey: "apikey",
        url: "https://iam.cloud.ibm.com/identity/token",
        client_id: "bx",
        client_secret: "bx"
      )
    rescue IBMCloudSdkCore::ApiException => e
      assert(e.to_s.instance_of?(String))
    end
  end

  def test_get_token
    access_token_layout = {
      "username" => "dummy",
      "role" => "Admin",
      "permissions" => %w[administrator manage_catalog],
      "sub" => "admin",
      "iss" => "sss",
      "aud" => "sss",
      "uid" => "sss",
      "iat" => 3600,
      "exp" => Time.now.to_i
    }

    access_token = JWT.encode(access_token_layout, "secret", "HS256", "kid": "230498151c214b788dd97f22b85410a5")

    response = {
      "access_token" => access_token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    iam_url = "https://iam.cloud.ibm.com/identity/token"
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      apikey: "apikey",
      url: iam_url,
      client_id: "bx",
      client_secret: "bx"
    )
    assert_equal(token_manager.access_token, access_token)
  end

  def test_client_id_only
    assert_raises do
      IBMCloudSdkCore::IAMTokenManager.new(
        apikey: "apikey",
        iam_access_token: "iam_access_token",
        iam_client_id: "client_id"
      )
    end
  end

  def test_client_secret_only
    assert_raises do
      IBMCloudSdkCore::IAMTokenManager.new(
        apikey: "apikey",
        iam_access_token: "iam_access_token",
        iam_client_secret: "client_secret"
      )
    end
  end

  def test_dont_leak_constants
    assert_nil(defined? DEFAULT_IAM_URL)
    assert_nil(defined? CONTENT_TYPE)
    assert_nil(defined? ACCEPT)
    assert_nil(defined? REQUEST_TOKEN_GRANT_TYPE)
    assert_nil(defined? REQUEST_TOKEN_RESPONSE_TYPE)
    assert_nil(defined? REFRESH_TOKEN_GRANT_TYPE)
  end
end
