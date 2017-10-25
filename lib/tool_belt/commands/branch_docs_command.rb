module ToolBelt
  module Command
    class BranchDocsCommand < Clamp::Command

      parameter 'config_file', 'Release configuration file'

      def execute
        config = ToolBelt::Config.new(config_file)

        unless config.options.project == 'katello'
          puts "This command currently only supports the katello project."
        end

        if File.exist?("repos/#{config.options.namespace}")
          DocsRepository.parse(config).update_for_release
        else
          puts "You must run `setup-environment` before `branch-docs`."
        end
      end
    end
  end
end
