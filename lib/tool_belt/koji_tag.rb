module ToolBelt
  class KojiTag

    attr_accessor :name, :based_off, :helper_tags, :inherits, :build_target, :external_repos,
                  :koji_tools, :build_package_group_source_tag, :arches, :build_groups
    attr_accessor :tools

    def initialize(hash = {})
      hash.each {|k,v| instance_variable_set("@#{k}",v)}
      self.tools = KojiTools.new
      fail "name cannot be blank #{hash.inspect}" if name.nil? || name.empty?
      fail "#{name} external repos specified without a build target" if !build_target && external_repos && external_repos.any?
      fail "#{name} requires build_target for build_comps_source_tag" if build_package_group_source_tag && !build_target
    end

    def process
      tools.ensure_tag_exists(name, arches, based_off)

      if build_target
        tools.ensure_tag_exists(build_target, arches)
        tools.ensure_build_target(name, build_target)

        if build_package_group_source_tag
          tools.ensure_package_group(build_package_group_source_tag, build_target, 'build')
          tools.ensure_package_group(build_package_group_source_tag, build_target, 'srpm-build')
        end

        if build_groups
          build_groups.each do |group, packages|
            tools.create_package_group(build_target, group)
            tools.add_group_packages(build_target, group, packages)
          end
        end

        tools.ensure_external_repos(build_target, external_repos) if external_repos && external_repos.any?
      end

      if helper_tags
        helper_tags.each do |tag, source_tag|
          tools.ensure_tag_exists(tag, arches, source_tag)
        end
      end

      if inherits
        inherits.each do |root_tag, branches_with_priority|
          tools.ensure_inherited(root_tag, branches_with_priority)
        end
      end

      tools.regen_repo(build_target) if build_target
    end
  end
end
