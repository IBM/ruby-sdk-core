# frozen_string_literal: true

require("json")
require_relative("./basic_authenticator.rb")
require_relative("./bearer_token_authenticator.rb")
require_relative("./cp4d_authenticator.rb")
require_relative("./iam_authenticator.rb")
require_relative("./no_auth_authenticator.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Authenticator
  class ConfigBasedAuthenticatorFactory
    # Checks the credentials file and VCAP_SERVICES environment variable
    # :param service_name: The service name
    # :return: the authenticator
    def get_authenticator(service_name:)
      config = get_service_properties(service_name)
      return construct_authenticator(config) unless config.nil? || config.empty?
    end

    def construct_authenticator(config)
      auth_type = config[:auth_type] || "iam"
      return BasicAuthenticator.new(config) if auth_type == "basic"
      return BearerTokenAuthenticator.new(config) if auth_type == "bearerToken"
      return CloudPakForDataAuthenticator.new(config) if auth_type == "cp4d"
      return IamAuthenticator.new(config) if auth_type == "iam"
      return NoAuthAUthenticator.new if auth_type == "noAuth"
    end
  end
end
