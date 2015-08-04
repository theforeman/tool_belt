require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class KojiBuilder

    CLIENT_OSES = %w(rhel5 rhel6 rhel7 fedora22 fedora23)
    SERVER_OSES = %w(rhel6 rhel7)
    KOJI_COMMAND = 'koji -c ~/.koji/katello-config'

    EXTERNAL_REPOS = {
      'rhel5' => ['rhel-5.9-server', 'epel-5'],
      'rhel6' => ['rhel-6.6-server', 'rhel-6.6-server-optional', 'epel-6'],
      'rhel7' => ['rhel-7.0-server', 'rhel-7.0-server-optional', 'epel-7']
    }

    VERSIONS = {
      'nightly' => 'nightly',
      '2.0' => '1.6',
      '2.1' => '1.7',
      '2.2' => '1.8',
      '2.3' => '1.9',
      '2.4' => '1.10',
      '3.0' => '1.11'
    }

    attr_reader :version, :systools

    def initialize(args = {})
      @katello_version = args.fetch(:katello_version, 'nightly') || 'nightly'
      @systools = args.fetch(:systools) || SysTools.new
      @foreman_version = VERSIONS[@katello_version]
    end

    def build_katello_tags(os)
      operating_systems = os.nil? ? CLIENT_OSES : os

      operating_systems.each do |os|
        puts "Building Katello tag for Katello #{@katello_version} on #{os}"
        puts "========================================================"

        # If tag exists, do not clone as this may grab unwanted packages
        # Tag cloning should only be done during initial tag creation for
        # a version and then not again unless done as a manual command outside
        # of this function
        if execute("list-tags katello-#{@katello_version}-#{os}").first.nil?
          execute("clone-tag katello-nightly-#{os} katello-#{@katello_version}-#{os}")
          execute("clone-tag katello-thirdparty-#{os} katello-#{@katello_version}-thirdparty-#{os}")
        end

        execute("add-tag katello-#{@katello_version}-#{os}-build  --arches=x86_64")

        if SERVER_OSES.include?(os)
          execute("add-tag katello-#{@katello_version}-#{os}-override")
          execute("add-tag-inheritance katello-#{@katello_version}-#{os}-build katello-#{@katello_version}-#{os}-override")
          execute("add-tag-inheritance katello-#{@katello_version}-#{os}-override katello-#{@katello_version}-#{os}")
          execute("add-tag-inheritance katello-#{@katello_version}-#{os} katello-#{@katello_version}-thirdparty-#{os}")
          execute("add-tag-inheritance katello-#{@katello_version}-#{os}-build foreman-plugins-#{@foreman_version}-#{os}-override --priority=2")
          execute("add-tag-inheritance katello-#{@katello_version}-#{os}-build foreman-#{@foreman_version}-#{os} --priority=3")
        end

        execute("add-target katello-#{@katello_version}-#{os} katello-#{@katello_version}-#{os}-build")

        add_external_repos(os, "katello-#{@katello_version}-#{os}-build")
        execute("add-external-repo centos-sclo-rh-rhel-#{os.split('rhel')[1]} -t katello-#{@katello_version}-#{os}-build")

        build_groups, _success = execute("list-groups katello-nightly-#{os}-build build")
        srpm_groups, _success = execute("list-groups katello-nightly-#{os}-build srpm-build")
        build_groups = parse_list_group(build_groups)
        srpm_groups = parse_list_group(srpm_groups)

        execute("add-group katello-#{@katello_version}-#{os}-build build")
        execute("add-group katello-#{@katello_version}-#{os}-build srpm-build")
        execute("add-group-pkg katello-#{@katello_version}-#{os}-build build #{build_groups.join(' ')}")
        execute("add-group-pkg katello-#{@katello_version}-#{os}-build srpm-build #{srpm_groups.join(' ')}")
        execute("regen-repo katello-#{@katello_version}-#{os}-build")

        puts ""
      end
    end

    def build_client_tags(os)
      operating_systems = os.nil? ? CLIENT_OSES : os

      operating_systems.each do |os|
        puts "Building client tag for Katello #{version} on #{os}"
        puts "========================================================"

        execute("add-tag katello-#{version_prefix}client-#{os}")
        execute("add-tag katello-#{version_prefix}client-#{os}-build --arches=x86_64")
        execute("add-tag-inheritance katello-#{version_prefix}client-#{os} katello-#{@katello_version}-#{os}")
        execute("add-tag-inheritance katello-#{version_prefix}client-#{os} katello-#{version_prefix}thirdparty-pulp-#{os}")
        execute("add-tag-inheritance katello-#{version_prefix}client-#{os} katello-#{version_prefix}thirdparty-pulp-#{os} --priority=2")
        execute("add-target katello-#{version_prefix}client-#{os} katello-#{version_prefix}client-#{os}-build")

        puts ""
      end
    end

    def build_pulp_tags(os)
      operating_systems = os.nil? ? CLIENT_OSES : os

      operating_systems.each do |os|
        puts "Building Pulp tag for Katello #{version} on #{os}"
        puts "========================================================"

        execute("add-tag katello-#{version_prefix}thirdparty-pulp-#{os}")
        execute("clone-tag katello-thirdparty-pulp-#{os} katello-#{@katello_version}-thirdparty-pulp-#{os}")
        execute("add-tag katello-#{version_prefix}thirdparty-pulp-#{os}-build --arches=x86_64")
        execute("add-target katello-#{version_prefix}thirdparty-pulp-#{os} katello-#{version_prefix}thirdparty-pulp-#{os}-build")
        add_external_repos(os, "katello-#{version_prefix}thirdparty-pulp-#{os}-build")

        puts ""
      end
    end

    def build_candlepin_tags(os)
      operating_systems = os.nil? ? SERVER_OSES : os

      operating_systems.each do |os|
        puts "Building Candlepin tag for Katello #{version} on #{os}"
        puts "========================================================"

        if execute("list-tags katello-#{version_prefix}thirdparty-candlepin-#{os}").first.nil?
          execute("clone-tag katello-thirdparty-candlepin-#{os} katello-#{@katello_version}-thirdparty-candlepin-#{os}")
        end

        execute("add-tag katello-#{version_prefix}thirdparty-candlepin-#{os}-build --arches=x86_64")
        execute("add-tag katello-#{version_prefix}thirdparty-candlepin-#{os}-override")
        execute("add-target katello-#{version_prefix}thirdparty-candlepin-#{os} katello-#{version_prefix}thirdparty-candlepin-#{os}-build")
        add_external_repos(os, "katello-#{version_prefix}thirdparty-candlepin-#{os}-build")
        execute("regen-repo katello-#{version_prefix}thirdparty-candlepin-#{os}-build")

        puts ""
      end
    end

    private

    def version_prefix
      (@katello_version == 'nightly') ? '' : "#{@katello_version}-"
    end

    def execute(command)
      @systools.execute("#{KOJI_COMMAND} #{command}")
    end

    def add_external_repos(os, tag)
      return false unless EXTERNAL_REPOS.keys.include?(os)

      EXTERNAL_REPOS[os].each do |repo|
        execute("add-external-repo #{repo} -t #{tag}")
      end
    end

    def parse_list_group(groups)
      return [] if groups.empty?
      groups = groups.split("\n")
      groups = groups[1..groups.length]
      groups.collect { |line| line.split(':').first.strip }
    end

  end
end
