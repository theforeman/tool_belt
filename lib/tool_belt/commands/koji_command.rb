require_relative 'commit_option'

module ToolBelt
  module Command
    class KojiCommand < Clamp::Command
      include ToolsOption

      parameter "config_file", "Release configuration file"
      option "--tag", 'TAG', "Only apply changes to specified tag instead of all"

      def execute
        setup_systools
        config = ToolBelt::Config.new(config_file)
        tags = if tag
                 config.options[:tags].select{ |t| t['name'] == tag }
               else
                 config.options[:tags]
               end
        builder = ToolBelt::KojiBuilder.new(tags)
        builder.create_tags
      end

    end
  end
end
