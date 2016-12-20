module ToolBelt
  module Command
    module ToolsOption

      def self.included(base)
        base.send :option, "--commit", :flag, "Run all system actions for real instead of the default dry run mode"
        base.send :option, "--debug", :flag, "Print debug output when running a command"
      end

      def systools
        ToolBelt::SysTools.new(:commit => commit?, :debug => debug?)
      end

      def setup_systools
        ToolBelt::SysTools.instance = systools
      end

    end
  end
end
