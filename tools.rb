#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/tool_belt')

Clamp.allow_options_after_parameters = true

class MainCommand < Clamp::Command

  subcommand "cherry-picks", "Calculate needed cherry picks for a given release configuration", ToolBelt::Command::CherryPickCommand
  subcommand "changelog", "Generate changelog for a given release", ToolBelt::Command::ChangelogCommand
  subcommand "branch", "Create and push the branch or tag for each repository as specified in the configuration", ToolBelt::Command::BranchCommand
  subcommand "branch-docs", "Generate docs for a given release", ToolBelt::Command::BranchDocsCommand
  subcommand "setup-environment", "Setup release environment for a given configuration", ToolBelt::Command::SetupEnvironmentCommand
  subcommand "check-deprecation-warnings", "Check codebase for outdated deprecation warnings", ToolBelt::Command::CheckDeprecationWarningsCommand
end

MainCommand.run
