module ToolBelt
  module Command
    class CheckDeprecationWarningsCommand < Clamp::Command
      parameter 'config_file', 'Release configuration file'
      option '--paths', 'PATHS',
             'Patterns within the repository to search, separated by a comma.',
             default: 'app/**/*.rb,lib/**/*.rb'

      def execute
        config = ToolBelt::Config.new(config_file)
        options = config.options
        repo_path = "repos/#{options.namespace}/#{options.project}/"
        unless File.exist?(repo_path)
          raise "Repo path #{repo_path} not found! Did you forget to run './tools.rb setup-environment #{config_file}' ?"
        end

        globs_to_scan = paths.split(',').map { |path| File.expand_path(path, repo_path) }
        paths_to_scan = Dir.glob(globs_to_scan)

        puts "\nScanning for deprecation warnings in #{globs_to_scan.join(', ')}\n\n"
        finder = ToolBelt::OutdatedDeprecationWarningFinder.new(paths_to_scan, options.release)
        current_outdated = finder.deprecations.select { |dep| dep[:outdated] == true }
        next_outdated = finder.deprecations.select { |dep| dep[:outdated_next_version] == true }

        if current_outdated.any?
          puts current_outdated_found
          current_outdated.each { |outdated_dep| puts current_outdated_message(outdated_dep, finder.current_version) }
        else
          puts "No currently outdated deprecation warnings found!\n".green
        end

        if next_outdated.any?
          puts next_outdated_found(finder.next_minor_version)
          next_outdated.each { |outdated_dep| puts next_outdated_message(outdated_dep) }
        else
          puts "No deprecation warnings found that will be outdated in the next version!\n".green
        end
      end

      private

      def current_outdated_found
        'Deprecation warnings were found with versions that are outdated, please check below and ' \
        'ensure both the deprecated functionality and the deprecation warning are removed if ' \
        "the deprecation is outdated in this release\n".red
      end

      def next_outdated_found(version)
        "Deprecation warnings were found marked for removal for the *next* release version #{version}. " \
        "Please check below and file issues aligned to #{version} to remove the functionality and the " \
        'deprecation warning. This will ensure the functionality is removed in time for the next ' \
        "release #{version}. The deprecation warning should stay in this release, only file issues for " \
        "its removal at this time.\n".yellow
      end

      def current_outdated_message(outdated_dep, version)
        "Deprecation warning at #{outdated_dep[:file]} line #{outdated_dep[:line]} is marked for " \
        "removal in version #{outdated_dep[:version]}, which is less than or equal to the specified " \
        "version of #{version}.\n\n"
      end

      def next_outdated_message(outdated_dep)
        "Deprecation warning at #{outdated_dep[:file]} line #{outdated_dep[:line]} is marked for " \
        "removal in version #{outdated_dep[:version]}, which is the *next* release version.\n\n"
      end
    end
  end
end
