#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/tool_belt')

class CherryPickCommand < Clamp::Command

  parameter "config_file", "Release configuration file"

  #subcommand "cherry-picks", "Calculate needed cherry picks for a given release configuration" do
    def execute
      config = ToolBelt::Config.new(config_file)
      release = config.options[:release]
      project = config.options[:project]
      ignores = config.options[:ignores] if config.options.key?(:ignores)
      repos = config.options[:repos]
      redmine_release_id = config.options[:redmine_release_id]
      picker = ToolBelt::CherryPicker.new(project, release, repos, redmine_release_id, ignores)
    end
  #end

end

class MainCommand < Clamp::Command

  subcommand "cherry-picks", "Calculate needed cherry picks for a given release configuration", CherryPickCommand

end

MainCommand.run
