module ToolBelt
  module Command
    class ProcedureCommand < Clamp::Command
      subcommand "branch", "Branch procedure for project" do
        parameter "project", "Project to generate procedure for"
        parameter "release", "Version that's currently in nightly in the major.minor format, like 1.20." do |value|
          raise ArgumentError.new('Release must be in major.minor, like 1.20') unless value =~ /^\d+\.\d+$/
          value
        end

        def execute
          context = {
            release: release,
            develop: bump_last(release),
          }

          render(project, 'branch', context)
        end
      end

      subcommand "release", "Release procedures for project" do
        parameter "project", "Project to generate procedure for"
        parameter "full-version", "Version that the branch will have - like 1.20.0-rc1" do |value|
          raise ArgumentError.new('Release must be in major.minor.patch or major.minor.patch-rcx, like 1.20.0 or 1.20.0-rc1') unless value =~ /^\d+\.\d+\.\d+(-rc\d+)?$/
          value
        end

        def execute
          version, extra = full_version.split('-', 2)
          major, minor, _ = version.split('.', 3)
          debian_full_version = version + (extra ? "~#{extra.downcase}" : '') + '-1'
          context = {
            is_rc: !extra.nil?,
            extra: extra,
            short_version: "#{major}.#{minor}", # 1.20
            debian_full_version: debian_full_version, # 1.20.0~rc1-1
            full_version: full_version, # 1.20.0-rc1
            version: version, # 1.20.0
          }

          render(project, 'release', context)
        end
      end

      subcommand "update", "Update procedure for project" do
        parameter "project", "Project to generate procedure for"

        def execute
          render(project, 'update', {})
        end
      end

      private

      def render(project, procedure, context)
        filename = procedure_filename(project, procedure)
        puts ToolBelt::Template.render_file(filename, context)
      end

      def procedure_filename(project, procedure)
        "procedures/#{project}/#{procedure}.md.erb"
      end

      def bump_last(version)
        parts = version.split('.')
        (parts[0..-2] + [(parts.last.to_i + 1).to_s]).join('.')
      end
    end
  end
end
