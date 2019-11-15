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
end
