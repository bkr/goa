require 'erb'

class GOA::Config
  class << self
    def database_config_file_path(engine_root)
      path = "config/database.yml"

      path = "#{path}.#{Rails.env}" if File.exist?(File.join(engine_root, "#{path}.#{Rails.env}"))

      File.join(engine_root, path)
    end

    def database_config(engine_root, config_env_override_key = nil)
      config_override_env = config_env_override_key && Rails.application.config.respond_to?(config_env_override_key) && Rails.application.config.send(config_env_override_key)

      env_key = config_override_env || Rails.env

      YAML.load(ERB.new(File.read(database_config_file_path(engine_root))).result, aliases: true)[env_key].symbolize_keys
    end
  end
end
