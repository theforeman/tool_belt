require 'erb'
require 'ostruct'

module ToolBelt
  module Template
    def self.render(template, vars)
      ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
    end

    def self.render_file(filename, context)
      self.render(File.read(filename), context)
    end
  end
end
