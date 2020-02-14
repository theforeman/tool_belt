module ToolBelt
  class OutdatedDeprecationWarningFinder
    attr_accessor :deprecations

    def initialize(paths, version)
      @paths = paths
      @version = version
      @deprecations = []
      error_if_empty(paths)
      scan_for_deprecations
    end

    def scan_for_deprecations
      @paths.select do |file|
        ast = ::Parser::CurrentRuby.parse(File.read(file))
        processor = ToolBelt::DeprecationWarningParser.new(file)
        processor.process(ast)

        next unless processor.versions_found.any?

        processor.versions_found.each do |version_found|
          if Gem::Version.new(version_found[:version]) <= current_version
            version_found[:outdated] = true
            @deprecations << version_found
          elsif Gem::Version.new(version_found[:version]) == next_minor_version
            version_found[:outdated_next_version] = true
            @deprecations << version_found
          end
        end
      end
    end

    def next_minor_version
      bump_minor_version(current_version)
    end

    def current_version
      Gem::Version.new(@version)
    end

    private

    def error_if_empty(paths_to_scan)
      if paths_to_scan.empty?
        raise "Couldn't find any files! Please check the path and try again"
      end
    rescue RuntimeError => e
      puts e.message.red
      exit 1
    end

    def bump_minor_version(version)
      version_segments = version.segments
      version_segments[1] += 1
      Gem::Version.new(version_segments[0, 2].join('.'))
    end
  end
end
