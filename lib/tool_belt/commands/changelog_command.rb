module ToolBelt
  module Command
    class ChangelogCommand < Clamp::Command

      parameter "config_file", "Release configuration file"
      option "--update-cache", :flag, "Re-download issues and cache them"
      option "--version", 'VERSION', "Version to check cherry picks for"

      def execute
        config = ToolBelt::Config.new(config_file, version)
        if update_cache?
          issue_cache = ToolBelt::IssueCache.new(config.options)
          issue_cache.load_issues(true)
        end
        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
        ToolBelt::Changelog.new(config.options, release_environment)
      end

    end
  end
end
