require 'yaml'
require 'ostruct'

module ToolBelt
  class Config

    attr_accessor :options

    def initialize(config_file, version = nil, bugzilla = false)
      configs = YAML.load_file(config_file)

      if bugzilla && valid_bugzilla?(configs)
        configs = add_bugzilla_release(configs, version)
      elsif valid_redmine?(configs)
        configs = add_redmine_release(configs, version)
      end

      self.options = OpenStruct.new(configs)
    end

    private

    def valid_bugzilla?(configs)
      required_fields = [:releases, :repos, :project]

      if required_fields.all? { |k| configs.keys.include?(k) } && !configs[:releases].empty?
        true
      else
        fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}."
      end
    end

    def add_bugzilla_release(configs, version)
      releases = configs[:releases]

      if version && !releases.map(&:to_s).include?(version)
        fail "Unknown version specified. Please ensure the releases field is configured { X.Y.Z }."
      end

      configs[:bugzilla] = true
      configs[:release] = version.nil? ? releases.first.to_s : version.to_s
      configs[:namespace] = "#{configs[:project]}_#{configs[:release]}"
      configs
    end

    def valid_redmine?(configs)
      required_fields = [:releases, :repos, :project]

      if required_fields.all? { |k| configs.keys.include?(k) } && !configs[:releases].keys.empty?
        true
      elsif !required_fields.all? { |k| configs.keys.include?(k) }
        fail "Configuration file is incomplete. Please ensure it includes #{required_fields - configs.keys}."
      elsif configs[:releases].keys.empty?
        fail "Configuration file is incomplete. Please ensure releases contains at least one entry of the form {version: X.Y, redmine_release_id: N}."
      end
    end

    def add_redmine_release(configs, version)
      releases = configs[:releases]

      if version && !releases.keys.map(&:to_s).include?(version)
        fail "Unknown version specified. Please ensure the releases field is configured {version: X.Y, redmine_release_id: N}."
      end

      configs[:release] = version.nil? ? releases.keys.first.to_s : version.to_s
      configs[:redmine_release_id] = configs[:releases][configs[:release].to_sym][:redmine_release_id]
      configs[:namespace] = "#{configs[:project]}_#{configs[:release]}"
      configs
    end

  end
end
