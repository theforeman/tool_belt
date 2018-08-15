module ToolBelt
  class KojiTools
    def initialize
      @systools = SysTools.instance
    end

    def ensure_tag_exists(tag_name, arches, based_off = nil)
      unless tag_exists?(tag_name)
        if based_off
          koji_change("clone-tag --latest-only --all #{based_off} #{tag_name}")
        else
          koji_change("add-tag #{tag_name} --arches=#{arches.join(',')}")
        end
      end
    end

    def ensure_external_repos(tag_name, external_repo_names)
      existing = get_external_repo_names(tag_name)
      needed = external_repo_names - existing
      unneeded = existing - external_repo_names

      needed.each do |repo_name|
        koji_change("add-external-repo --tag=#{tag_name} #{repo_name}")
      end
      unneeded.each do |repo_name|
        koji_change("remove-external-repo #{repo_name} #{tag_name}")
      end
    end

    def ensure_packages(tag_name, packages)
      koji_change("add-pkg #{tag_name} #{packages.join(' ')} --owner=kojiadm")
    end

    def ensure_package_group(dest_tag, package_group, options)
      unless has_package_group?(dest_tag, package_group)
        create_package_group(dest_tag, package_group)
      end
      packages = if source_tag = options.fetch(:source_tag, false)
                   packages_for_group(source_tag, package_group)
                 else
                   options.fetch(:packages)
                 end

      existing_packages = packages_for_group(dest_tag, package_group)
      add_group_packages(dest_tag, package_group, packages) if (packages - existing_packages).any?
    end

    def create_package_group(tag, group)
      koji_change("add-group #{tag} #{group}")
    end

    def add_group_packages(tag, group, package_list)
      koji_change("add-group-pkg #{tag} #{group} #{package_list.join(' ')}")
    end

    def has_package_group?(tag, group)
      output, success = koji_info("list-groups #{tag} #{group}")
      success && output && output.size > 0
    end

    def packages_for_group(tag, group)
      output, success = koji_info("list-groups #{tag} #{group}")
      if success
        output.split("\n")[1..-1].map{|line| line.split(':')[0].strip}
      else
        []
      end
    end

    def ensure_build_target(name, build_target)
      unless build_target?(name, build_target)
        koji_change("add-target #{name} #{build_target}")
      end
    end

    def ensure_inherited(root, branches_with_priority)
      #stringify the keys
      branches_with_priority = branches_with_priority.collect{|k,v| [k.to_s, v]}.to_h

      current_branches = get_inherited(root)
      if current_branches != branches_with_priority
        current_branches.each{|branch, priority| remove_inheritance(root, branch)}
        branches_with_priority.each{|branch, priority| create_inheritance(root, branch, priority)}
      end
    end

    def regen_repo(tag)
      koji_change("regen-repo #{tag}")
    end

    def tag_exists?(tag_name)
      koji_info("taginfo #{tag_name}")[1]
    end

    def build_target?(name, build_target)
      output, success = koji_info("taginfo #{name}")
      if success
        lines = output.split("\n")
        index = lines.index("Targets that build into this tag:")
        if index
          return lines[index+1].include?("(#{build_target},")
        else
          return false
        end
      else
        false
      end
    end

    def get_external_repo_names(tag_name)
      output, success = koji_info("list-external-repos --tag=#{tag_name}")
      if success
        lines = output.split("\n")[2..-1]
        lines.map{|line| line.split(' ')[1]}
      else
        []
      end
    end

    def get_inherited(root)
      output, success = koji_info("taginfo #{root}")
      branches = {}
      return branches unless success
      lines = output.split("\n")
      in_inheritance = false
      lines.each do |line|
        if in_inheritance
          tag, priority = parse_inheritance_line(line)
          branches[tag] = priority.to_i
        else
          in_inheritance = (line == 'Inheritance:')
        end
      end
      branches
    end

    #takes a line such as "0    .... katello-3.2-rhel7-override [1172]", and returns a tuple of [tag, priority]
    def parse_inheritance_line(line)
      splits = line.strip.split(' ')
      [splits[2], splits[0]]
    end

    def create_inheritance(root, branch, priority)
      koji_change("add-tag-inheritance --priority=#{priority} #{root} #{branch}")
    end

    def remove_inheritance(root, branch)
      koji_change("remove-tag-inheritance #{root} #{branch}")
    end

    def koji_info(command)
      @systools.execute("#{KojiBuilder::KOJI_COMMAND} #{command}", true)
    end

    def koji_change(command)
      _, success = @systools.execute("#{KojiBuilder::KOJI_COMMAND} #{command}")
      raise 'Failed to run koji command' unless success
    end
  end
end
