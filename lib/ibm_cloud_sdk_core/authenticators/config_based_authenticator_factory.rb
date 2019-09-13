# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")
require_relative("./basic_authenticator.rb")
require_relative("./bearer_token_authenticator.rb")
require_relative("./cp4d_authenticator.rb")
require_relative("./iam_authenticator.rb")
require_relative("./no_auth_authenticator.rb")
require_relative("../utils.rb")

module IBMCloudSdkCore
  # Authenticator
  class ConfigBasedAuthenticatorFactory < Authenticator
    # Checks the credentials file and VCAP_SERVICES environment variable
    # :param service_name: The service name
    # :return: the authenticator
    def get_authenticator(service_name:)
      config = get_service_properties(service_name)
      return construct_authenticator(config) unless config.nil? || config.empty?
    end

    def construct_authenticator(config)
      if config[:auth_type].nil?
        auth_type = "iam"
      else
        auth_type = config[:auth_type]
      end
      config.delete(:url) unless config[:url].nil?
      config[:url] = config[:auth_url] unless config[:auth_url].nil?
      return BasicAuthenticator.new(config) if auth_type.casecmp(AUTH_TYPE_BASIC).zero?
      return BearerTokenAuthenticator.new(config) if auth_type.casecmp(AUTH_TYPE_BEARER_TOKEN).zero?
      return CloudPakForDataAuthenticator.new(config) if auth_type.casecmp(AUTH_TYPE_CP4D).zero?
      return IamAuthenticator.new(config) if auth_type.casecmp(AUTH_TYPE_IAM).zero?
      return NoAuthAuthenticator.new if auth_type.casecmp(AUTH_TYPE_NO_AUTH).zero?
    end
  end
end
