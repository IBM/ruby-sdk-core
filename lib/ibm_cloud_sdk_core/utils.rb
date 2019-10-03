# frozen_string_literal: true

DEFAULT_CREDENTIALS_FILE_NAME = "ibm-credentials.env"

def get_service_properties(service_name)
  # - 1) Credential file
  config = load_from_credential_file(service_name)
  # - 2) Environment variables
  config = load_from_environment_variables(service_name) if config.nil? || config.empty?
  # - 3) VCAP_SERVICES env variable
  config = load_from_vcap_services(service_name) if config.nil? || config.empty?
  config
end

def check_bad_first_or_last_char(str)
  return str.start_with?("{", "\"") || str.end_with?("}", "\"") unless str.nil?
end

# Initiates the credentials based on the credential file
def load_from_credential_file(service_name, separator = "=")
  credential_file_path = ENV["IBM_CREDENTIALS_FILE"]

  # Top-level directory of the project
  if credential_file_path.nil?
    file_path = File.join(File.dirname(__FILE__), "/../../" + DEFAULT_CREDENTIALS_FILE_NAME)
    credential_file_path = file_path if File.exist?(file_path)
  end

  # Home directory
  if credential_file_path.nil?
    file_path = ENV["HOME"] + "/" + DEFAULT_CREDENTIALS_FILE_NAME
    credential_file_path = file_path if File.exist?(file_path)
  end

  return if credential_file_path.nil?

  file_contents = File.open(credential_file_path, "r")
  config = {}
  file_contents.each_line do |line|
    key_val = line.strip.split(separator)
    unless line.start_with?("#") && key.length == 2
      key = parse_key(key_val[0].downcase, service_name) unless key_val[0].nil?
      config.store(key.to_sym, key_val[1]) unless key.nil?
    end
  end
  config
end

def load_from_environment_variables(service_name)
  config = {}
  ENV.each do |key, val|
    parsed_key = parse_key(key.downcase, service_name) unless key.nil?
    config.store(parsed_key.to_sym, val) unless parsed_key.nil?
  end
  config
end

def parse_key(key, service_name)
  key[service_name.length + 1, key.length] if key.include?(service_name)
end

def load_from_vcap_services(service_name)
  vcap_services = ENV["VCAP_SERVICES"]
  unless vcap_services.nil?
    services = JSON.parse(vcap_services)
    config = {}
    credentials = services[service_name][0]["credentials"] if services.key?(service_name)
    return config if credentials.nil?

    credentials.each do |key, val|
      config.store(key.to_sym, val)
    end
    config[:auth_type] = "basic" if !config[:username].nil? && !config[:password].nil?
    config[:auth_type] = "iam" unless config[:apikey].nil?
    return config
  end
  nil
end
