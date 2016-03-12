require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class PulpRepositoryUpdater

    attr_accessor :katello_version, :pulp_version, :systools, :beta

    def initialize(katello_version, pulp_version, release, systools = SysTools.new)
      self.katello_version = katello_version
      self.pulp_version = pulp_version
      self.systools = systools
      self.beta = release == 'beta'
    end

    def update_server
      ['6', '7'].each do |os_version|
        output = compare_repos(os_version)
        tag = koji_tag(os_version)
        #untag_packages(removed_packages(output), tag)
        add_packages(new_packages(output), tag)
        tag_packages(updated_packages(output), tag)
      end
    end

    def update_client
      ['5', 'fedora-22', 'fedora-23'].each do |os_version|
        output = compare_repos(os_version, true)
        tag_packages(updated_packages(output), koji_tag(os_version))
      end
    end

    private

    def compare_repos(os_version, client = false)
      katello_repo = client ? katello_client_repo(os_version) : katello_pulp_repo(os_version)
      setup_pulp_repo(os_version)
      command = "repodiff --simple --old=#{katello_repo} --new=file://#{Dir.pwd}/tmp/"
      @systools.syscall(command)[0]
    end

    def setup_pulp_repo(os_version)
      @systools.syscall('rm -rf tmp/')
      Dir.mkdir('tmp')
      Dir.chdir('tmp') do
        @systools.syscall("wget #{pulp_repo(os_version)}")
        index = File.read('index.html')
        rpms = index.scan(/href=".*.rpm"/).collect { |link| link.split('href=')[1].gsub('"', '') }
        rpms.each do |rpm|
          @systools.syscall("wget #{pulp_repo(os_version)}#{rpm}")
        end
        @systools.syscall("sudo yum -y install createrepo") unless @systools.syscall('rpm -q createrepo')[1]
        @systools.syscall("createrepo .")
      end
    end

    def removed_packages(output)
      removed = []

      output.split("\n").each do |line|
        if line.start_with?('Removed package:')
          removed << line.split('Removed package:  ')[1]
        end
      end

      removed
    end

    def new_packages(output)
      added = []
      output.split("\n").each do |line|
        if line.start_with?('New package:')
          added << line.split('New package: ')[1]
        end
      end

      added
    end

    def updated_packages(output)
      updated = []

      output.split("\n").each do |line|
        if line.include?(' -> ')
          updated << line.split(' ->  ')[1]
        end
      end

      updated
    end

    def katello_pulp_repo(os_version)
      "https://fedorapeople.org/groups/katello/releases/source/srpm/#{@katello_version}/pulp/RHEL/#{os_version}/"
    end

    def katello_client_repo(os_version)
      os_name = os_version.include?('fedora') ? 'Fedora' : 'RHEL'
      os_version = os_version.split('fedora-')[1] if os_version.include?('fedora')
      "https://fedorapeople.org/groups/katello/releases/source/srpm/#{@katello_version}/client/#{os_name}/#{os_version}/"
    end

    def pulp_repo(os_version)
      if beta
        "https://repos.fedorapeople.org/repos/pulp/pulp/beta/#{@pulp_version}/#{os_version}/src/"
      else
        "https://repos.fedorapeople.org/repos/pulp/pulp/stable/#{@pulp_version}/#{os_version}/src/"
      end
    end

    def koji_tag(os_version)
      prefix = katello_version == 'nightly' ? 'katello' : "katello-#{katello_version}"

      if os_version.include?('fedora')
        "#{prefix}-thirdparty-pulp-fedora#{os_version.split('fedora-')[1]}"
      else
        "#{prefix}-thirdparty-pulp-rhel#{os_version}"
      end
    end

    def untag_packages(packages, tag)
      puts "\n=== Removing Packages Phase ====\n"
      puts "The following packages are being removed from #{tag}: "
      puts "#{packages.join("\n")}"

      packages.each do |package|
        @systools.execute("koji -c ~/.koji/katello-config untag-pkg #{tag} #{package}")
      end
    end

    def add_packages(packages, tag)
      puts ""
      puts "=== Adding Packages Phase ===="
      puts "The following packages are being added as new to #{tag}: "
      puts "#{packages.join("\n")}"

      packages.each do |package|
        @systools.execute("koji -c ~/.koji/katello-config add-pkg #{tag} #{package.split(/-[0-9]/).first} --owner=jsherril")
      end

      packages.each do |package|
        @systools.execute("koji -c ~/.koji/katello-config tag-pkg #{tag} #{package}")
      end
    end

    def tag_packages(packages, tag)
      puts "\n=== Tagging Packages Phase ====\n"
      puts "The following packages are being tagged into #{tag}: "
      puts "#{packages.join("\n")}"

      packages.each do |package|
        @systools.execute("koji -c ~/.koji/katello-config tag-pkg #{tag} #{package}")
      end
    end
  end
end
