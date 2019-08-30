# frozen_string_literal: true

require_relative("./../test_helper.rb")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the CP4D Token Manager
class CP4DTokenManagerTest < Minitest::Test
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
      "accessToken" => token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }
    stub_request(:get, "https://the.sixth.one/v1/preauth/validateAuth")
      .with(
        headers: {
          "Authorization" => "Basic eW91Om1l",
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 200, body: response.to_json, headers: {})

    token_manager = IBMCloudSdkCore::CP4DTokenManager.new(
      url: "https://the.sixth.one",
      username: "you",
      password: "me"
    )
    token_response = token_manager.send(:request_token)
    assert_equal(response, token_response)
  end

  def test_request_token_fails
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:get, "https://the.sixth.one/v1/preauth/validateAuth")
      .with(
        headers: {
          "Authorization" => "Basic eW91Om1l",
          "Host" => "the.sixth.one"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    begin
      IBMCloudSdkCore::CP4DTokenManager.new(
        url: "https://the.sixth.one",
        username: "you",
        password: "me"
      )
    rescue IBMCloudSdkCore::ApiException => e
      assert(e.to_s.instance_of?(String))
    end
  end
end
