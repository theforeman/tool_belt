require 'yaml'
require 'ostruct'

module ToolBelt
  class Config

    attr_accessor :options

    def initialize(config_file, version=nil)
      configs = YAML.load_file(config_file)
      valid?(configs)
      configs = add_release(configs, version)
      self.options = OpenStruct.new(configs)
    end

    private

    def required_fields
      [:releases, :repos, :project]
    end

    def valid?(configs)
      valid = required_fields.all? do |key|
        configs.keys.include?(key)
      end

      fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}." if !valid || configs[:releases].keys.empty?
      fail "Configuration file is incomplete. Please ensure releases contains at least one entry of the form {version: X.Y, redmine_release_id: N}." if configs[:releases].keys.empty?
      valid
    end

    def add_release(configs, version)
      releases = configs[:releases]
      fail "Unknown version specified. Please ensure the releases field is configured {version: X.Y, redmine_release_id: N}." if !version.nil? && !releases.keys.map(&:to_s).include?(version)
      configs[:release] = version.nil? ? releases.keys.first.to_s : version.to_s
      configs[:redmine_release_id] = configs[:releases][configs[:release].to_sym][:redmine_release_id]
      configs
    end

  end
end
