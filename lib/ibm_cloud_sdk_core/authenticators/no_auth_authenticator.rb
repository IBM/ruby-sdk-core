# frozen_string_literal: true

require("json")
require_relative("./authenticator.rb")

module IBMCloudSdkCore
  # Authenticator
  class NoAuthAuthenticator < Authenticator
    @authentication_type = "noAuth"

    def authenticate
      nil
    end

    def validate
      nil
    end
  end
end
