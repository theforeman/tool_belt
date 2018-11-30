module ToolBelt
  class MashScript

    attr_accessor :filename, :tag, :gpgkey, :strict_keys

    def initialize(filename, options = {})
      self.filename = filename
      options.each {|k,v| instance_variable_set("@#{k}",v)}
    end

    def write_file
      File.open(filename, 'w') do |file|
        file.write(template)
      end
    end

    def template
      <<-EOF
[#{self.tag}]
rpm_path = %(arch)s/os/Packages
repodata_path = %(arch)s/os/
source_path = source/SRPMS
debuginfo = False
multilib = False
multilib_method = devel
tag = #{self.tag}
inherit = True
strict_keys = #{self.strict_keys}
keys = #{self.gpgkey}
arches = x86_64
      EOF
    end
  end
end
