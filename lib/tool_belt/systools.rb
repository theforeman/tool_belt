require 'English'
require 'open3'

module ToolBelt
  class SysTools

    attr_reader :commit

    def initialize(args = {})
      @commit = args.fetch(:commit, false)
    end

    def execute(command)
      if @commit
        syscall(command)
      else
        puts "[noop] #{command}"
        return "", true
      end
    end

    private

    def syscall(*cmd)
      stdout, stderr, status = Open3.capture3(*cmd)
      if status.success?
        return stdout.slice!(1..-(1 + $INPUT_RECORD_SEPARATOR.size)), status.success? # strip trailing eol
      else
        puts "ERROR: #{stdout}" unless stdout.empty?
        puts "ERROR: #{stderr}" unless stderr.empty?
        status.success?
      end
    end

  end
end
