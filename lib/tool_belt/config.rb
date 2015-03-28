require 'yaml'
require 'ostruct'

module ToolBelt
  class Config

    attr_accessor :options

    def initialize(config_file)
      configs = YAML.load_file(config_file)
      valid?(configs)
      self.options = OpenStruct.new(configs)
    end

    private

    def required_fields
      [:release, :redmine_release_id, :repos, :project]
    end

    def valid?(configs)
      valid = required_fields.all? do |key|
        configs.keys.include?(key)
      end

      fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}." if !valid
      valid
    end

  end
end
