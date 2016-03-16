require_relative 'commit_option'

module ToolBelt
  module Command
    class PulpRepositoryUpdateCommand < Clamp::Command

      include ToolsOption

      parameter "katello_version", "Katello version of Pulp to compare against"
      parameter "pulp_version", "Pulp stable version to compare against"
      parameter "release", "'stable' or 'beta' Which pulp repository to use."

      def execute
        package_updater = ToolBelt::PulpRepositoryUpdater.new(katello_version, pulp_version, release, systools)
        package_updater.update_server
        package_updater.update_client
      end

    end
  end
end
