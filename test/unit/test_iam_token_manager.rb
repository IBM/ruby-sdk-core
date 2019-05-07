# frozen_string_literal: true

require_relative("./../test_helper.rb")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the IAM Token Manager
class IAMTokenManagerTest < Minitest::Test
  def test_request_token
    response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    # Use default iam_url, client id/secret
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token"
    )
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "iam_apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:request_token)
    assert_equal(response, token_response)
  end

  def test_request_token_fails
    iam_url = "https://iam.bluemix.net/identity/token"
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token",
      iam_url: iam_url
    )
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:post, "https://iam.bluemix.net/identity/token")
      .with(
        body: { "apikey" => "iam_apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.bluemix.net"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    assert_raises do
      token_manager.send(:request_token)
    end
  end

  def test_request_token_fails_catch_exception
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token"
    )
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "iam_apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 401, body: response.to_json, headers: {})
    begin
      token_manager.send(:request_token)
    rescue IBMCloudSdkCore::ApiException => e
      assert(e.to_s.instance_of?(String))
    end
  end

  def test_refresh_token
    iam_url = "https://iam.cloud.ibm.com/identity/token"
    response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token",
      iam_url: iam_url
    )
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "grant_type" => "refresh_token", "refresh_token" => "" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:refresh_token)
    assert_equal(response, token_response)
  end

  def test_is_token_expired
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token",
      iam_url: "iam_url"
    )
    token_manager.token_info = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => Time.now.to_i + 6000,
      "refresh_token" => "jy4gl91BQ"
    }

    refute(token_manager.send(:token_expired?))
    token_manager.token_info["expiration"] = Time.now.to_i - 3600
    assert(token_manager.send(:token_expired?))
  end

  def test_is_refresh_token_expired
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_access_token: "iam_access_token",
      iam_url: "iam_url"
    )
    token_manager.token_info = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => Time.now.to_i,
      "refresh_token" => "jy4gl91BQ"
    }

    refute(token_manager.send(:refresh_token_expired?))
    token_manager.token_info["expiration"] = Time.now.to_i - (8 * 24 * 3600)
    assert(token_manager.send(:token_expired?))
  end

  def test_get_token
    iam_url = "https://iam.cloud.ibm.com/identity/token"
    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_url: iam_url
    )
    token_manager.user_access_token = "user_access_token"

    token = token_manager.token
    assert_equal(token_manager.user_access_token, token)

    response = {
      "access_token" => "hellohello",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => "iam_apikey", "grant_type" => "urn:ibm:params:oauth:grant-type:apikey", "response_type" => "cloud_iam" },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_manager.user_access_token = ""
    token = token_manager.token
    assert_equal("hellohello", token)

    token_manager.token_info["expiration"] = Time.now.to_i - (20 * 24 * 3600)
    token = token_manager.token
    assert_equal("hellohello", token)

    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_manager.token_info["expiration"] = Time.now.to_i - 4000
    token = token_manager.token
    assert_equal("hellohello", token)

    token_manager.token_info = {
      "access_token" => "dummy",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => Time.now.to_i + 3600,
      "refresh_token" => "jy4gl91BQ"
    }
    token = token_manager.token
    assert_equal("dummy", token)
  end

  def test_client_id_only
    assert_raises do
      IBMCloudSdkCore::IAMTokenManager.new(
        iam_apikey: "iam_apikey",
        iam_access_token: "iam_access_token",
        iam_client_id: "client_id"
      )
    end
  end

  def test_client_secret_only
    assert_raises do
      IBMCloudSdkCore::IAMTokenManager.new(
        iam_apikey: "iam_apikey",
        iam_access_token: "iam_access_token",
        iam_client_secret: "client_secret"
      )
    end
  end

  def test_request_token_nondefault_client_id_secret
    response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey",
      iam_client_id: "foo",
      iam_client_secret: "bar"
    )
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(basic_auth: %w[foo bar]).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:request_token)
    assert_equal(response, token_response)
  end

  def test_request_token_default_client_id_secret
    response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    token_manager = IBMCloudSdkCore::IAMTokenManager.new(
      iam_apikey: "iam_apikey"
    )
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(basic_auth: %w[bx bx]).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:request_token)
    assert_equal(response, token_response)
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
