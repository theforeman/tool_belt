require 'yaml'

module ToolBelt
  class Config

    attr_accessor :options

    def initialize(config_file)
      self.options = YAML.load_file(config_file)
      fail "Configuration file is incomplete. Please ensure it includes #{required_fields - @options.keys}." if !valid?
    end

    def required_fields
      [:release, :redmine_release_id, :repos, :project]
    end

    def valid?
      required_fields.all? do |key|
        options.keys.include?(key)
      end
    end

  end
end
