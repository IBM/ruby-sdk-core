# frozen_string_literal: true

require_relative("./../test_helper.rb")
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
      icp4d_url: "https://the.sixth.one",
      username: "you",
      password: "me"
    )
    stub_request(:get, "https://the.sixth.one")
      .with(
        headers: {
          "Authorization" => "Basic Og==",
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})
    token_response = token_manager.send(:request, method: "get", url: "https://the.sixth.one")
    assert_equal(response, token_response)
    token_manager.access_token("token")
    assert_equal(token_manager.instance_variable_get(:@user_access_token), "token")
  end

  def test_request_token_fails
    token_manager = IBMCloudSdkCore::JWTTokenManager.new(
      icp4d_url: "https://the.sixth.one",
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
          "Authorization" => "Basic Og==",
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    begin
      token_manager.send(:request, method: "get", url: "https://the.sixth.one")
    rescue IBMCloudSdkCore::ApiException => e
      assert(e.to_s.instance_of?(String))
    end
  end

  def test_request_token_exists
    token_manager = IBMCloudSdkCore::JWTTokenManager.new(
      icp4d_url: "https://the.sixth.one",
      username: "you",
      password: "me",
      token_info: { "access_token" => "token" }
    )
    token_response = token_manager.send(:token)
    assert_equal("token", token_response)
  end
end
