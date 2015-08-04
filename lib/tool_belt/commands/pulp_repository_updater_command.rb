require_relative 'commit_option'

module ToolBelt
  module Command
    class PulpRepositoryUpdateCommand < Clamp::Command

      include CommitOption

      parameter "katello_version", "Katello version of Pulp to compare against"
      parameter "pulp_version", "Pulp stable version to compare against"

      def execute
        package_updater = ToolBelt::PulpRepositoryUpdater.new(katello_version, pulp_version, @systools)
        package_updater.update_server
        package_updater.update_client
      end

    end
  end
end
