require 'erb'
require 'ostruct'

module ToolBelt
  module Template
    def self.render_file(filename, context)
      erb = ERB.new(File.read(filename), trim_mode: '-')
      erb.filename = File.expand_path(filename)
      erb.result(OpenStruct.new(context).instance_eval { binding })
    end
  end
end
