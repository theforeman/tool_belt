#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/tool_belt')

class CherryPickCommand < Clamp::Command

  parameter "config_file", "Release configuration file"
  option "--update-cache", :flag, "Re-download issues and cache them"

  def execute
    config = ToolBelt::Config.new(config_file)
    if update_cache?
      issue_cache = ToolBelt::IssueCache.new(config.options)
      issue_cache.load_issues(true)
    end
    release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
    picker = ToolBelt::CherryPicker.new(config.options, release_environment)
  end

end

class ChangelogCommand < Clamp::Command

  parameter "config_file", "Release configuration file"
  option "--update-cache", :flag, "Re-download issues and cache them"

  def execute
    config = ToolBelt::Config.new(config_file)
    if update_cache?
      issue_cache = ToolBelt::IssueCache.new(config.options)
      issue_cache.load_issues(true)
    end
    release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
    ToolBelt::Changelog.new(config.options, release_environment)
  end

end

class SetupEnvironmentCommand < Clamp::Command

  parameter "config_file", "Release configuration file"

  def execute
    config = ToolBelt::Config.new(config_file)
    release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos)
    release_environment.setup
  end

end

class PulpRepositoryUpdateCommand < Clamp::Command

  parameter "katello_version", "Katello version of Pulp to compare against"
  parameter "pulp_version", "Pulp stable version to compare against"
  option "--commit", :flag, "Runs the update command against Koji, otherwise runs in as a dry run and prints potential updates"

  def execute
    package_updater = ToolBelt::PulpRepositoryUpdater.new(katello_version, pulp_version, commit?)
    package_updater.update_server
    package_updater.update_client
  end

end

class MainCommand < Clamp::Command

  subcommand "cherry-picks", "Calculate needed cherry picks for a given release configuration", CherryPickCommand
  subcommand "changelog", "Generate changelog for a given release", ChangelogCommand
  subcommand "setup-environment", "Setup release environment for a given configuration", SetupEnvironmentCommand
  subcommand "pulp-repo-update", "Update Katello's Pulp repository based on parameters", PulpRepositoryUpdateCommand

end

MainCommand.run
