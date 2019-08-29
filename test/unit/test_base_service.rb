# frozen_string_literal: true

require("json")
require("jwt")
require_relative("./../test_helper.rb")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/basic_authenticator")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/config_based_authenticator_factory")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the base service
class BaseServiceTest < Minitest::Test
  def test_wrong_username
    assert_raises do
      IBMCloudSdkCore::BasicAuthenticator.new(
        username: "\"username",
        password: "password"
      )
    end
  end

  def test_wrong_apikey
    assert_raises do
      IBMCloudSdkCore::IamAuthenticator.new(
        apikey: "{apikey"
      )
    end
  end

  def test_wrong_url
    assert_raises do
      IBMCloudSdkCore::IamAuthenticator.new(
        apikey: "apikey",
        url: "url}"
      )
    end
  end

  def test_correct_creds_and_headers
    authenticator = IBMCloudSdkCore::BasicAuthenticator.new(
      username: "username",
      password: "password"
    )
    service = IBMCloudSdkCore::BaseService.new(
      display_name: "Assistant",
      authenticator: authenticator
    )
    service.add_default_headers(
      headers: {
        "X-Watson-Learning-Opt-Out" => "1",
        "X-Watson-Test" => "1"
      }
    )
    service.headers("analytics" => "example")
    refute_nil(service)
  end

  def test_set_credentials_from_path_in_env
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    service = IBMCloudSdkCore::BaseService.new(display_name: "Visual Recognition")
    assert_equal(service.instance_variable_get(:@url), "https://gateway.ronaldo.com")
    refute_nil(service)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end

  def test_set_credentials_from_path_in_env_nlu
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    service = IBMCloudSdkCore::BaseService.new(display_name: "Natural Language Understanding")
    assert_equal(service.instance_variable_get(:@url), "https://gateway.messi.com")
    refute_nil(service)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end

  def test_set_credentials_from_path_in_env_bearer_token
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    authenticator = IBMCloudSdkCore::ConfigBasedAuthenticatorFactory.new.get_authenticator(service_name: "leo_messi")
    service = IBMCloudSdkCore::BaseService.new(display_name: "Leo Messi", url: "some.url", authenticator: authenticator)
    assert_equal(authenticator.authentication_type, "bearerToken")
    refute_nil(service)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end

  def test_vcap_services
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    authenticator = IBMCloudSdkCore::ConfigBasedAuthenticatorFactory.new.get_authenticator(service_name: "salah")
    service = IBMCloudSdkCore::BaseService.new(display_name: "salah", authenticator: authenticator)
    assert_equal(authenticator.username, "mo")
    assert_equal(service.display_name, "salah")
  end

  def test_dummy_request
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: "", headers: {})
    authenticator = IBMCloudSdkCore::ConfigBasedAuthenticatorFactory.new.get_authenticator(service_name: "Salah")
    service = IBMCloudSdkCore::BaseService.new(display_name: "Salah", authenticator: authenticator, url: "https://we.the.best")
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal("", service_response.result)
  end

  def test_dummy_request_form_data
    service = IBMCloudSdkCore::BaseService.new(
      display_name: "Assistant",
      apikey: "apikey",
      iam_access_token: "token",
      url: "https://gateway.watsonplatform.net/"
    )
    form_data = {}
    file = File.open(Dir.getwd + "/resources/cnc_test.pdf")
    filename = file.path if filename.nil? && file.respond_to?(:path)
    form_data[:file] = HTTP::FormData::File.new(file, content_type: "application/octet-stream", filename: filename)

    stub_request(:post, "https://gateway.watsonplatform.net/").with do |req|
      # Test the headers.
      assert_equal(req.headers["Accept"], "application/json")
      assert_match(%r{\Amultipart/form-data}, req.headers["Content-Type"])
    end
    service.request(
      method: "POST",
      form: form_data,
      headers: { "Accept" => "application/json" },
      url: ""
    )
  end

  def test_dummy_request_fails
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    response = {
      "code" => "500",
      "error" => "Oh no"
    }
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Host" => "we.the.best"
        }
      ).to_return(status: 500, body: response.to_json, headers: {})
    authenticator = IBMCloudSdkCore::ConfigBasedAuthenticatorFactory.new.get_authenticator(service_name: "Salah")
    service = IBMCloudSdkCore::BaseService.new(display_name: "Salah", authenticator: authenticator, url: "https://we.the.best")
    assert_raises do
      service.request(method: "GET", url: "/music", headers: {})
    end
  end

  def test_dummy_request_icp
    response = {
      "text" => "I want financial advice today.",
      "created" => "2016-07-11T16:39:01.774Z",
      "updated" => "2015-12-07T18:53:59.153Z"
    }
    headers = {
      "Content-Type" => "application/json"
    }
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    authenticator = IBMCloudSdkCore::BasicAuthenticator.new(
      username: "apikey",
      password: "icp-xyz"
    )
    service = IBMCloudSdkCore::BaseService.new(
      display_name: "Assistant",
      authenticator: authenticator,
      url: "https://we.the.best"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end

  def test_for_cp4d_authenticator
    authenticator = IBMCloudSdkCore::CloudPakForDataAuthenticator.new(
      username: "hello",
      password: "world",
      url: "hello.world"
    )
    refute_nil(authenticator)
  end

  # def test_CP4D_disable_ssl
  #   authenticator = IBMCloudSdkCore::CloudPakForDataAuthenticator.new(
  #     username: "username",
  #     password: "password"
  #   )
  #   IBMCloudSdkCore::BaseService.new(
  #     display_name: "Assistant",
  #     url: "http://the.com",
  #     authenticator: authenticator
  #   )
  #   stub_request(:get, "http://the.com/music")
  #     .with(
  #       headers: {
  #         "Authorization" => "Basic Og==",
  #         "Host" => "the.com"
  #       }
  #     ).to_return(status: 200, body: {}.to_json, headers: {})
  #   assert_equal(authenticator.instance_variable_get(:@access_token), "token")
  # end
end
