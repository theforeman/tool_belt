require 'parser/current'

module ToolBelt
  class DeprecationWarningParser < ::Parser::AST::Processor
    attr_reader :versions_found

    def initialize(file)
      super()
      @file = file
      @versions_found = []
    end

    def on_begin(node)
      node.children.each { |c| process(c) }
    end

    def on_send(node)
      method_class, method_name, *args = node.children
      version_regex = /\d+\.\d+/

      if %i[api_deprecation_warning deprecation_warning].include?(method_name)
        *method_classes = method_class.children if method_class&.children
        if method_classes.include?(:Deprecation)
          args.select! { |arg| arg.to_s =~ version_regex }
          if args.any?
            found_version = args.first.children.first
            extracted_version = found_version.to_s.scan(version_regex).first
            @versions_found << {
              version: extracted_version,
              file: @file,
              line: node.loc.line
            }
          end
        end
      end
    end
  end
end
