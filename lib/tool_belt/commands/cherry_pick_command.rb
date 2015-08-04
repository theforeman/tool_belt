module ToolBelt
  module Command
    class CherryPickCommand < Clamp::Command

      parameter "config_file", "Release configuration file"
      option "--update-cache", :flag, "Re-download issues and cache them"

      def execute
        config = ToolBelt::Config.new(config_file)
        if update_cache?
          issue_cache = ToolBelt::IssueCache.new(config.options)
          issue_cache.load_issues(true)
        end
        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
        picker = ToolBelt::CherryPicker.new(config.options, release_environment)
      end

    end
  end
end
