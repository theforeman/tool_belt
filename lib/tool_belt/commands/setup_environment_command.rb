module ToolBelt
  module Command
    class SetupEnvironmentCommand < Clamp::Command

      parameter "config_file", "Release configuration file"
      option "--bugzilla", :flag, "Setup environment with Bugzilla access"
      option "--github-username", "USERNAME", "Add users forks for each repository that is setup, value must be the username on github"

      def execute
        config = ToolBelt::Config.new(config_file, nil, bugzilla?)
        release_environment = ToolBelt::ReleaseEnvironment.new(config.options.repos, config.options.namespace)
        release_environment.setup(:github_username => github_username)
      end

    end
  end
end
