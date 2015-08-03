require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class ReleaseEnvironment

    attr_accessor :repos

    def initialize(repos)
      self.repos = repos
    end

    def setup
      Dir.mkdir('repos') if !File.exist?('repos')

      Dir.chdir('repos') do
        @repos.each do |name, repo|
          syscall("git clone #{repo[:repo]}") if !File.exist?(name.to_s)
          Dir.chdir(name.to_s) do
            syscall("git checkout #{repo[:branch]}")
          end
        end
      end
    end

    def repos
      @repos
    end

    def repo_location(repo_name)
      "repos/#{repo_name}"
    end

    def repo_names
      @repos.keys
    end

    def main_repo
      repo = @repos.find { |name, repo| repo[:main] }
      repo.nil? ? '' : repo.first
    end

    def commit_in_repos?(repo_names, message)
      repo_names.any? do |repo_name|
        commit_in_repo?(repo_name, message)
      end
    end

    def git_escape(string)
      string = string.split("`")[0] if string.include?("`")
      string.gsub('"', '\"').gsub('[', '\[')
    end

    def commit_in_repo?(repo_name, message)
      Dir.chdir(repo_location(repo_name)) do
        output = syscall('git log --grep="' + git_escape(message.split("\n").first) + '"').first
        if output.is_a?(String)
          if output.empty?
            return false
          else
            return true
          end
        end
      end
    end

  end
end
