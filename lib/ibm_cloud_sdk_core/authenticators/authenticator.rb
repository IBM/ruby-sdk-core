# frozen_string_literal: true

require("json")

module IBMCloudSdkCore
  # Authenticator
  class Authenticator
    AUTH_TYPE_BASIC = "basic"
    AUTH_TYPE_BEARER_TOKEN = "bearerToken"
    AUTH_TYPE_CP4D = "cp4d"
    AUTH_TYPE_IAM = "iam"
    AUTH_TYPE_NO_AUTH = "noAuth"

    def authenticate
      # Adds the Authorization header, if possible
    end

    def validate
      # Checks if all the inputs needed are present
    end
  end
end
