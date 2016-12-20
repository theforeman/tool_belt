require_relative 'commit_option'

module ToolBelt
  module Command
    class KojiCommand < Clamp::Command
      include ToolsOption

      parameter "config_file", "Release configuration file"

      def execute
        setup_systools
        config = ToolBelt::Config.new(config_file)
        builder = ToolBelt::KojiBuilder.new(config.options[:tags])
        builder.create_tags
      end

    end
  end
end
