# frozen_string_literal: true

require("json")

module IBMCloudSdkCore
  # Custom exception class for errors returned from the APIs
  class ApiException < StandardError
    attr_reader :code, :error, :info, :transaction_id, :global_transaction_id
    # :param HTTP::Response response: The response object from the API
    def initialize(code: nil, error: nil, info: nil, transaction_id: nil, global_transaction_id: nil, response: nil)
      if code.nil? || error.nil?
        @code = response.code
        @error = response.reason
        unless response.body.empty?
          body_hash = JSON.parse(response.body.to_s)
          error_message = body_hash["errors"] && body_hash["errors"][0] ? body_hash["errors"][0]["message"] : nil
          @code = body_hash["code"] || body_hash["error_code"] || body_hash["status"]
          @error = error_message || body_hash["error"] || body_hash["message"] || body_hash["errorMessage"]
          %w[code error_code status errors error message].each { |k| body_hash.delete(k) }
          @info = body_hash
        end
      else
        # :nocov:
        @code = code
        @error = error
        @info = info
        # :nocov:
      end
      @transaction_id = transaction_id || response.headers["X-Dp-Watson-Tran-Id"]
      @global_transaction_id = global_transaction_id || response.headers["X-Global-Transaction-Id"]
    end

    def to_s
      msg = "Error: #{@error}, Code: #{@code}"
      msg += ", Information: #{@info}" unless @info.nil?
      msg += ", X-dp-watson-tran-id: #{@transaction_id}" unless @transaction_id.nil?
      msg += ", X-global-transaction-id: #{@global_transaction_id}" unless @global_transaction_id.nil?
      msg
    end
  end
end
