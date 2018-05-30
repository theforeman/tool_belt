require_relative 'debug_option'

module ToolBelt
  module Command
    class ChangelogCommand < Clamp::Command

      include DebugOption

      parameter "config_file", "Release configuration file"
      option "--version", 'VERSION', "Version to check cherry picks for"

      def execute
        config = ToolBelt::Config.new(config_file, version)
        release_environment = ToolBelt::ReleaseEnvironment.new(
          config.options.repos,
          config.options.namespace,
          systools
        )
        ToolBelt::Changelog.new(config.options, release_environment)
      end

    end
  end
end
