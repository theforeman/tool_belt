module ToolBelt
  module Command
    class CherryPickCommand < Clamp::Command
      parameter "config_file", "Release configuration file"
      option "--version", 'VERSION', "Version to generate changelog for"

      def execute
        config = ToolBelt::Config.new(config_file, version)

        issue_service = ToolBelt::IssueService.new(config.options)
        issues = issue_service.load_issues

        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos, config.options.namespace)
        release_environment.update_repos

        picker = ToolBelt::CherryPicker.new(config.options, release_environment, issues)
      end
    end
  end
end
