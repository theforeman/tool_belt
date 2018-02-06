module ToolBelt
  module Command
    class CherryPickCommand < Clamp::Command

      parameter "config_file", "Release configuration file"
      option "--update-cache", :flag, "Re-download issues and cache them"
      option "--version", 'VERSION', "Version to generate changelog for"

      def execute
        config = ToolBelt::Config.new(config_file, version)

        issue_cache = ToolBelt::IssueCache.new(config.options)
        issues = issue_cache.load_issues(update_cache?)

        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos, config.options.namespace)
        release_environment.update_repos

        picker = ToolBelt::CherryPicker.new(config.options, release_environment, issues)
      end

    end
  end
end
