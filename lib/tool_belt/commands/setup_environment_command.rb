module ToolBelt
  module Command
    class SetupEnvironmentCommand < Clamp::Command

      parameter "config_file", "Release configuration file"
      option "--github-username", "USERNAME", "Add users forks for each repository that is setup, value must be the username on github"
      option "--version", 'VERSION', "Version to build for"

      def execute
        config = ToolBelt::Config.new(config_file, version)
        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos, config.options.namespace)
        release_environment.setup(:github_username => github_username)
      end

    end
  end
end
