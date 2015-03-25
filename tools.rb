#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'lib/tool_belt')

if ARGV.empty?
  puts "Please provide a valid configuration file as the first parameter"
  exit 1
else
  config = ToolBelt::Config.new(ARGV[0])
end

release = config.options[:release]
project = config.options[:project]
ignores = config.options[:ignores] if config.options.key?(:ignores)
repos = config.options[:repos]
redmine_release_id = config.options[:redmine_release_id]
picker = ToolBelt::CherryPicker.new(project, release, repos, redmine_release_id, ignores)
