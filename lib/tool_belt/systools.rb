require 'English'
require 'open3'

module ToolBelt
  class SysTools

    attr_reader :commit, :debug

    def initialize(args = {})
      @commit = args.fetch(:commit, false)
      @debug = args.fetch(:debug, false)
    end

    def execute(command)
      if @commit
        syscall(command)
      else
        puts "[noop] #{command}"
        return "", true
      end
    end

    def syscall(*cmd)
      puts cmd if @debug
      stdout, stderr, status = Open3.capture3(*cmd)
      if status.success?
        return stdout.slice!(1..-(1 + $INPUT_RECORD_SEPARATOR.size)), status.success? # strip trailing eol
      else
        if @debug
          puts "ERROR: #{stdout}" unless stdout.empty?
          puts "ERROR: #{stderr}" unless stderr.empty?
        end
        return '', status.success?
      end
    end

  end
end
