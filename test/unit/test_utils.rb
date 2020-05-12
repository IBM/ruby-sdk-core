# frozen_string_literal: true

require("json")
require("jwt")
require_relative("./../test_helper.rb")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/basic_authenticator")
require_relative("./../../lib/ibm_cloud_sdk_core/authenticators/config_based_authenticator_factory")
require("webmock/minitest")

WebMock.disable_net_connect!(allow_localhost: true)

# Unit tests for the utility methods
class UtilsTest < Minitest::Test
  def test_explicitly_true
    assert(explicitly_true("true"))
    assert(explicitly_true("True"))
    assert(explicitly_true(true))

    assert_equal(explicitly_true("false"), false)
    assert_equal(explicitly_true("False"), false)
    assert_equal(explicitly_true("someothervalue"), false)
    assert_equal(explicitly_true(""), false)
    assert_equal(explicitly_true(false), false)
    assert_equal(explicitly_true(nil), false)
  end

  def test_get_configuration_credential_file
    file_path = File.join(File.dirname(__FILE__), "../../resources/ibm-credentials.env")
    ENV["IBM_CREDENTIALS_FILE"] = file_path
    # get properties
    config = get_service_properties("service_1")
    auth_type = config[:auth_type] unless config.nil?
    apikey = config[:apikey] unless config.nil?
    auth_url = config[:auth_url] unless config.nil?
    client_id = config[:client_id] unless config.nil?
    client_secret = config[:client_secret] unless config.nil?
    service_url = config[:url] unless config.nil?

    assert !auth_type.nil?
    assert !apikey.nil?
    assert !auth_url.nil?
    assert !client_id.nil?
    assert !client_secret.nil?
    assert !service_url.nil?

    assert_equal("iam", auth_type)
    assert_equal("V4HXmoUtMjohnsnow=KotN", apikey)
    assert_equal("https://iamhost/iam/api=", auth_url)
    assert_equal("somefake========id", client_id)
    assert_equal("==my-client-secret==", client_secret)
    assert_equal("service1.com/api", service_url)
    ENV.delete("IBM_CREDENTIALS_FILE")
  end

  def test_get_configuration_from_env
    # Service1 auth properties configured with IAM and a token containing '='
    ENV["SERVICE_1_AUTH_TYPE"] = "iam"
    ENV["SERVICE_1_APIKEY"] = "V4HXmoUtMjohnsnow=KotN"
    ENV["SERVICE_1_CLIENT_ID"] = "somefake========id"
    ENV["SERVICE_1_CLIENT_SECRET"] = "==my-client-secret=="
    ENV["SERVICE_1_AUTH_URL"] = "https://iamhost/iam/api="
    # Service1 service properties
    ENV["SERVICE_1_URL"] = "service1.com/api"
    # get properties
    config = get_service_properties("service_1")
    auth_type = config[:auth_type] unless config.nil?
    apikey = config[:apikey] unless config.nil?
    auth_url = config[:auth_url] unless config.nil?
    client_id = config[:client_id] unless config.nil?
    client_secret = config[:client_secret] unless config.nil?
    service_url = config[:url] unless config.nil?

    assert !auth_type.nil?
    assert !apikey.nil?
    assert !auth_url.nil?
    assert !client_id.nil?
    assert !client_secret.nil?
    assert !service_url.nil?

    assert_equal("iam", auth_type)
    assert_equal("V4HXmoUtMjohnsnow=KotN", apikey)
    assert_equal("https://iamhost/iam/api=", auth_url)
    assert_equal("somefake========id", client_id)
    assert_equal("==my-client-secret==", client_secret)
    assert_equal("service1.com/api", service_url)

    ENV.delete("SERVICE_1_AUTH_TYPE")
    ENV.delete("SERVICE_1_APIKEY")
    ENV.delete("SERVICE_1_CLIENT_ID")
    ENV.delete("SERVICE_1_CLIENT_SECRET")
    ENV.delete("SERVICE_1_AUTH_URL")
    ENV.delete("SERVICE_1_URL")
  end

  def test_get_configuration_from_vcap
    ENV["VCAP_SERVICES"] = JSON.parse(File.read(Dir.getwd + "/resources/vcap-testing.json")).to_json
    # get properties
    config = get_service_properties("equals-sign-test")
    auth_type = config[:auth_type] unless config.nil?
    apikey = config[:apikey] unless config.nil?
    iam_url = config[:iam_url] unless config.nil?
    service_url = config[:url] unless config.nil?

    assert !auth_type.nil?
    assert !apikey.nil?
    assert !iam_url.nil?
    assert !service_url.nil?

    assert_equal("iam", auth_type)
    assert_equal("V4HXmoUtMjohnsnow=KotN", apikey)
    assert_equal("https://iamhost/iam/api=", iam_url)
    assert_equal("https://gateway.watsonplatform.net/testService", service_url)

    ENV.delete("VCAP_SERVICES")
  end
end
