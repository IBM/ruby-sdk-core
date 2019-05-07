# frozen_string_literal: true

require("json")
require_relative("./../test_helper.rb")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the base service
class BaseServiceTest < Minitest::Test
  def test_wrong_username
    assert_raises do
      IBMCloudSdkCore::BaseService.new(
        username: "\"username",
        password: "password"
      )
    end
  end

  def test_wrong_apikey
    assert_raises do
      IBMCloudSdkCore::BaseService.new(
        iam_apikey: "{apikey"
      )
    end
  end

  def test_wrong_url
    assert_raises do
      IBMCloudSdkCore::BaseService.new(
        iam_apikey: "apikey",
        url: "url}"
      )
    end
  end

  def test_correct_creds_and_headers
    service = IBMCloudSdkCore::BaseService.new(
      username: "username",
      password: "password"
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

  def test_iam_access_token
    token = "new$token"
    service = IBMCloudSdkCore::BaseService.new(
      url: "https://we.the.best"
    )
    response = service.iam_access_token(iam_access_token: token)
    assert_equal(response, token)
  end

  def test_set_credentials_from_path_in_env
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    service = IBMCloudSdkCore::BaseService.new(display_name: "Visual Recognition")
    assert_equal(service.url, "https://gateway.ronaldo.com")
    refute_nil(service)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end

  def test_vcap_services
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    service = IBMCloudSdkCore::BaseService.new(vcap_services_name: "salah", use_vcap_services: true)
    assert_equal(service.username, "mo")
  end

  def test_dummy_request
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: "", headers: {})
    service = IBMCloudSdkCore::BaseService.new(display_name: "Salah", url: "https://we.the.best")
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal("", service_response.result)
  end

  def test_dummy_request_form_data
    service = IBMCloudSdkCore::BaseService.new(
      iam_apikey: "apikey",
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
    service = IBMCloudSdkCore::BaseService.new(display_name: "Salah", url: "https://we.the.best")
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
          "Authorization" => "Basic YXBpa2V5OmljcC14eXo=",
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    service = IBMCloudSdkCore::BaseService.new(
      url: "https://we.the.best",
      username: "apikey",
      password: "icp-xyz"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end

  def test_dummy_request_icp_iam_apikey
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
          "Authorization" => "Basic YXBpa2V5OmljcC14eXo=",
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    service = IBMCloudSdkCore::BaseService.new(
      url: "https://we.the.best",
      iam_apikey: "icp-xyz"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end

  def test_dummy_request_icp_iam_apikey_cred_file
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
          "Authorization" => "Basic YXBpa2V5OmljcC14eXo=",
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    service = IBMCloudSdkCore::BaseService.new(
      url: "https://we.the.best",
      display_name: "messi"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end

  def test_dummy_request_username_apikey
    response = {
      "text" => "I want financial advice today.",
      "created" => "2016-07-11T16:39:01.774Z",
      "updated" => "2015-12-07T18:53:59.153Z"
    }
    token_response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    headers = {
      "Content-Type" => "application/json"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: {
          "apikey" => "xyz",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Connection" => "close",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com",
          "User-Agent" => "http.rb/4.1.1"
        }
      ).to_return(status: 200, body: token_response.to_json, headers: {})
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Authorization" => "Bearer oAeisG8yqPY7sFR_x66Z15",
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    service = IBMCloudSdkCore::BaseService.new(
      url: "https://we.the.best",
      username: "apikey",
      password: "xyz"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end

  def test_dummy_request_username_apikey_cred_file
    response = {
      "text" => "I want financial advice today.",
      "created" => "2016-07-11T16:39:01.774Z",
      "updated" => "2015-12-07T18:53:59.153Z"
    }
    token_response = {
      "access_token" => "oAeisG8yqPY7sFR_x66Z15",
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "expiration" => 1_524_167_011,
      "refresh_token" => "jy4gl91BQ"
    }

    headers = {
      "Content-Type" => "application/json"
    }
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: {
          "apikey" => "xyz",
          "grant_type" => "urn:ibm:params:oauth:grant-type:apikey",
          "response_type" => "cloud_iam"
        },
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic Yng6Yng=",
          "Connection" => "close",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "iam.cloud.ibm.com",
          "User-Agent" => "http.rb/4.1.1"
        }
      ).to_return(status: 200, body: token_response.to_json, headers: {})
    stub_request(:get, "https://we.the.best/music")
      .with(
        headers: {
          "Authorization" => "Bearer oAeisG8yqPY7sFR_x66Z15",
          "Host" => "we.the.best"
        }
      ).to_return(status: 200, body: response.to_json, headers: headers)
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    service = IBMCloudSdkCore::BaseService.new(
      display_name: "ronaldo",
      url: "https://we.the.best"
    )
    service_response = service.request(method: "GET", url: "/music", headers: {})
    assert_equal(response, service_response.result)
  end
end
