require_relative 'debug_option'

module ToolBelt
  module Command
    class ChangelogCommand < Clamp::Command
      include DebugOption

      parameter "config_file", "Release configuration file"
      option "--version", 'VERSION', "Version to create changelog for"

      def execute
        config = ToolBelt::Config.new(config_file, version)

        release_environment = ToolBelt::ReleaseEnvironment.new(
          config.options.repos,
          config.options.namespace,
          systools
        )

        issue_service = IssueService.new(config.options)
        issues = issue_service.load_issues(with_version_priors: true)

        ToolBelt::Changelog.new(config.options, release_environment, issues)
      end
    end
  end
end
