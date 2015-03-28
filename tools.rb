#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/tool_belt')

class CherryPickCommand < Clamp::Command

  parameter "config_file", "Release configuration file"

  def execute
    config = ToolBelt::Config.new(config_file)
    release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
    picker = ToolBelt::CherryPicker.new(config.options, release_environment)
  end

end

class ChangelogCommand < Clamp::Command

  parameter "config_file", "Release configuration file"

  def execute
    config = ToolBelt::Config.new(config_file)
    release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
    ToolBelt::Changelog.new(config.options, release_environment)
  end

end

class MainCommand < Clamp::Command

  subcommand "cherry-picks", "Calculate needed cherry picks for a given release configuration", CherryPickCommand
  subcommand "changelog", "Generate changelog for a given release", ChangelogCommand

end

MainCommand.run
