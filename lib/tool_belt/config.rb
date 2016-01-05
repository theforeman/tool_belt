require 'yaml'
require 'ostruct'

module ToolBelt
  class Config

    attr_accessor :options

    def initialize(config_file, version=nil)
      configs = YAML.load_file(config_file)
      validate_bugzilla?(configs)
      configs = add_bugzilla_release(configs, version)
      #validate_redmine?(configs)
      #configs = add_release(configs, version)
      self.options = OpenStruct.new(configs)
    end

    private

    def validate_bugzilla?(configs)
      required_fields = [:releases, :repos]

      valid = required_fields.all? do |key|
        configs.keys.include?(key)
      end

      fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}." if !valid || configs[:releases].empty?
      valid
    end

    def add_bugzilla_release(configs, version)
      releases = configs[:releases]
      fail "Unknown version specified. Please ensure the releases field is configured {version: X.Y, redmine_release_id: N}." if !version.nil? && !releases.map(&:to_s).include?(version)
      configs[:release] = version.nil? ? releases.first.to_s : version.to_s
      configs[:namespace] = "#{configs[:project]}_#{configs[:release]}"
      configs
    end

    def validate_redmine?(configs)
      required_fields = [:releases, :repos, :project]

      valid = required_fields.all? do |key|
        configs.keys.include?(key)
      end

      fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}." if !valid || configs[:releases].keys.empty?
      fail "Configuration file is incomplete. Please ensure releases contains at least one entry of the form {version: X.Y, redmine_release_id: N}." if configs[:releases].keys.empty?
      valid
    end

    def add_redmine_release(configs, version)
      releases = configs[:releases]
      fail "Unknown version specified. Please ensure the releases field is configured {version: X.Y, redmine_release_id: N}." if !version.nil? && !releases.keys.map(&:to_s).include?(version)
      configs[:release] = version.nil? ? releases.keys.first.to_s : version.to_s
      configs[:redmine_release_id] = configs[:releases][configs[:release].to_sym][:redmine_release_id]
      configs[:namespace] = "#{configs[:project]}_#{configs[:release]}"
      configs
    end

  end
end
