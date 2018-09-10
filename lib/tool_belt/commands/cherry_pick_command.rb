module ToolBelt
  module Command
    class CherryPickCommand < Clamp::Command
      parameter "config_file", "Release configuration file"
      option "--version", 'VERSION', "Which version to pick for. Defaults to first version in the config"

      def execute
        config = ToolBelt::Config.new(config_file, version)

        issue_service = ToolBelt::IssueService.new(config.options)
        issues = issue_service.load_issues(true)

        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos, config.options.namespace)
        release_environment.update_repos

        picker = ToolBelt::CherryPicker.new(config.options, release_environment, issues)
      end
    end
  end
end
