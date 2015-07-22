require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class PulpRepositoryUpdater

    attr_accessor :katello_version, :pulp_version, :commit

    def initialize(katello_version, pulp_version, commit=false)
      self.katello_version = katello_version
      self.pulp_version = pulp_version
      self.commit = commit
    end

    def update_server
      ['6', '7'].each do |os_version|
        output = compare_repos(os_version)
        tag = koji_tag(os_version)
        untag_packages(removed_packages(output), tag)
        add_packages(new_packages(output), tag)
        tag_packages(updated_packages(output), tag)
      end
    end

    def update_client
      ['5', '6', '7', 'fedora-20', 'fedora-21'].each do |os_version|
        output = compare_repos(os_version, true)
        tag_packages(updated_packages(output), koji_tag(os_version, true))
      end
    end

    private

    def compare_repos(os_version, client=false)
      katello_repo = client ? katello_client_repo(os_version) : katello_pulp_repo(os_version)
      command = "repodiff --archlist=noarch --simple --old=#{katello_repo} --new=#{pulp_repo(os_version)}"
      syscall(command)
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
      "https://fedorapeople.org/groups/katello/releases/yum/#{@katello_version}/pulp/RHEL/#{os_version}/x86_64/"
    end

    def katello_client_repo(os_version)
      os_name = os_version.include?('fedora') ? 'Fedora' : 'RHEL'
      os_version = os_version.split('fedora-')[1] if os_version.include?('fedora')
      "https://fedorapeople.org/groups/katello/releases/yum/#{@katello_version}/client/#{os_name}/#{os_version}/x86_64/"
    end

    def pulp_repo(os_version)
      "https://repos.fedorapeople.org/repos/pulp/pulp/stable/#{@pulp_version}/#{os_version}/x86_64/"
    end

    def koji_tag(os_version, client=false)
      return "katello-thirdparty-pulp-rhel#{os_version}" unless client

      if os_version.include?('fedora')
        "katello-nightly-fedora#{os_version.split('fedora-')[1]}"
      else
        "katello-nightly-rhel#{os_version}"
      end
    end

    def untag_packages(packages, tag)
      puts "\n=== Removing Packages Phase ====\n"
      puts "The following packages are being removed from #{tag}: "
      puts "#{packages.join("\n")}"
      run("koji-katello untag-pkg #{tag} #{packages.join(' ')}")
    end

    def add_packages(packages, tag)
      puts ""
      puts "=== Adding Packages Phase ===="
      puts "The following packages are being added as new to #{tag}: "
      puts "#{packages.join("\n")}"

      packages.each do |package|
        run("koji-katello add-pkg #{tag} #{package.split(/-[0-9]/).first} --owner=jsherrill")
      end

      run("koji-katello tag-pkg #{tag} #{packages.join(' ')}")
    end

    def tag_packages(packages, tag)
      puts "\n=== Tagging Packages Phase ====\n"
      puts "The following packages are being tagged into #{tag}: "
      puts "#{packages.join("\n")}"
      run("koji-katello tag-pkg #{tag} #{packages.join(' ')}")
    end

    def run(command)
      if @commit
        syscall(command)
      else
        puts command
      end
    end
  end
end
