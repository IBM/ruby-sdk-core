# frozen_string_literal: true

require("json")
require_relative("./authenticator")

module IBMCloudSdkCore
  # Authenticator
  class NoAuthAuthenticator < Authenticator
    def initialize
      @authentication_type = AUTH_TYPE_NO_AUTH
    end

    def authenticate(*)
      nil
    end

    def validate
      nil
    end
  end
end
