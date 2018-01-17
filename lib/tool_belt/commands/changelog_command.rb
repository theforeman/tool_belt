require_relative 'debug_option'

module ToolBelt
  module Command
    class ChangelogCommand < Clamp::Command

      include DebugOption

      parameter "config_file", "Release configuration file"
      option "--update-cache", :flag, "Re-download issues and cache them"
      option "--version", 'VERSION', "Version to check cherry picks for"
      option "--omit-gh-link", :flag, "Do not include the link to Github commit"

      def execute
        config = ToolBelt::Config.new(config_file, version)
        if update_cache?
          issue_cache = ToolBelt::IssueCache.new(config.options)
          issue_cache.load_issues(true)
        end
        release_environment = ToolBelt::ReleaseEnvironment.new(
          config.options.repos,
          config.options.namespace,
          systools
        )
        ToolBelt::Changelog.new(config.options, release_environment, omit_gh_link?)
      end

    end
  end
end
