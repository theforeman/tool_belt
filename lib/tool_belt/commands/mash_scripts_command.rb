require_relative 'commit_option'

module ToolBelt
  module Command
    class MashScriptsCommand < Clamp::Command
      include ToolsOption

      parameter "config_file", "Release configuration file"

      def execute
        setup_systools
        config = ToolBelt::Config.new(config_file)
        builder = ToolBelt::MashScriptsBuilder.new(config)
        builder.create_mash_scripts
      end

    end
  end
end
