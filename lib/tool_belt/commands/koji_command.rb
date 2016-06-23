require_relative 'commit_option'

module ToolBelt
  module Command
    class KojiCommand < Clamp::Command

      module OsClientOption
        def self.included(base)
          base.send :option, "--os", "OS", "Subset of operating systems to create tags for" do |os|
            operating_systems = %w(rhel5 rhel6 rhel7 fedora-22 fedora-23)
            os = os.split(',')
            signal_usage_error "OS must be one or more of #{operating_systems}" unless (os - operating_systems).empty?
            os
          end
        end
      end

      module OsServerOption
        def self.included(base)
          base.send :option, "--os", "OS", "Subset of operating systems to create tags for" do |os|
            operating_systems = %w(rhel6 rhel7)
            os = os.split(',')
            signal_usage_error "OS must be one or more of #{operating_systems}" unless (os - operating_systems).empty?
            os
          end
        end
      end

      module KatelloVersionOption
        def self.included(base)
          base.send :option, "--katello-version", "KATELLO_VERSION", "Katello version to build client tags for" do |version|
            version
          end
        end
      end

      class BuildClientTagCommand < Clamp::Command
        include ToolsOption
        include OsClientOption
        include KatelloVersionOption

        def execute
          koji_builder = KojiBuilder.new(:katello_version => katello_version, :systools => systools)
          koji_builder.build_client_tags(os)
        end
      end

      class BuildPulpTagCommand < Clamp::Command
        include ToolsOption
        include OsClientOption
        include KatelloVersionOption

        def execute
          koji_builder = KojiBuilder.new(:katello_version => katello_version, :systools => systools)
          koji_builder.build_pulp_tags(os)
        end
      end

      class BuildCandlepinTagCommand < Clamp::Command
        include ToolsOption
        include OsServerOption
        include KatelloVersionOption

        def execute
          koji_builder = KojiBuilder.new(:katello_version => katello_version, :systools => systools)
          koji_builder.build_candlepin_tags(os)
        end
      end

      class BuildKatelloTagCommand < Clamp::Command
        include ToolsOption
        include OsServerOption
        include KatelloVersionOption

        def execute
          koji_builder = KojiBuilder.new(:katello_version => katello_version, :systools => systools)
          koji_builder.build_katello_tags(os)
        end
      end

      subcommand "build-client-tags", "Builds new client tags for a given version", BuildClientTagCommand
      subcommand "build-pulp-tags", "Builds new pulp tags for a given version", BuildPulpTagCommand
      subcommand "build-candlepin-tags", "Builds new pulp tags for a given version", BuildCandlepinTagCommand
      subcommand "build-katello-tags", "Builds new Katello tags for a given version", BuildKatelloTagCommand

    end
  end
end
