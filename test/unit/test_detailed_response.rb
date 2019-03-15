# frozen_string_literal: true

require_relative("./../test_helper.rb")
require("webmock/minitest")
require("http")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the IAM Token Manager
class DetailedResponseTest < Minitest::Test
  def test_detailed_response
    res = IBMCloudSdkCore::DetailedResponse.new(status: 200, headers: {}, body: {}, response: { code: 401 })
    assert_equal(res.status, 200)
  end

  def test_detailed_response_when_no_arguments
    assert_raises do
      IBMCloudSdkCore::DetailedResponse.new
    end
  end

  def test_detailed_response_when_only_response
    response = IBMCloudSdkCore::DetailedResponse.new(response: HTTP::Response.new(status: 401, version: 1, body: {}))
    assert_equal(response.status, 401)
  end
end
