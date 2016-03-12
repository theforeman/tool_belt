module ToolBelt
  module Command
    module DebugOption

      def self.included(base)
        base.send :option, "--debug", :flag, "Print debug output when running a command"
      end

      def systools
        ToolBelt::SysTools.new(:commit => true, :debug => debug?)
      end

    end
  end
end
