require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class KojiBuilder
    KOJI_COMMAND = system("which kkoji") ? 'kkoji' : 'koji'

    def initialize(tags = [])
      @tags = tags.map{|tag| KojiTag.new(tag)}
    end

    def create_tags
      @tags.each do |tag|
        puts "\n\nPROCESSING #{tag.name}"
        tag.process
      end
    end
  end
end
