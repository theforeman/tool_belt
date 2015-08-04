module ToolBelt
  module Command
    module CommitOption

      def self.included(base)
        base.send :option, "--commit", :flag, "Run all system actions for real instead of the default dry run mode"
      end

      def systools
        ToolBelt::SysTools.new(:commit => commit?)
      end

    end
  end
end
