Dir[File.dirname(__FILE__) + '/commands/*.rb'].each { |file| require file }

module ToolBelt
  module Command
  end
end
