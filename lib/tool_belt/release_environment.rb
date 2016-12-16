require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class ReleaseEnvironment

    attr_reader :systools, :repos, :release

    def initialize(repos, release, systools = SysTools.new(:commit => true))
      @repos = repos
      @release = release
      @systools = systools
    end

    def setup(args = {})
      github_username = args.fetch(:github_username, nil)

      Dir.mkdir("repos") unless File.exist?("repos")
      Dir.mkdir(release_directory) unless File.exist?(release_directory)

      Dir.chdir(release_directory) do
        @repos.each do |name, repo|
          @systools.execute("git clone #{repo[:repo]} #{name}") if !File.exist?(name.to_s)

          Dir.chdir(name.to_s) do
            @systools.execute("git remote set-url origin #{add_username(repo[:repo], github_username)}") if github_username

            if repo[:version_branch]
              if branch_exists?("origin/#{repo[:branch]}") &&
                @systools.execute("git checkout origin/#{repo[:branch]}")
              else
                create_branch(repo[:repo], repo[:branch])
              end
            end

            if github_username
              @systools.execute("git remote add #{github_username} #{repository_fork(github_username, repo[:repo])}")
            end

            @systools.execute("git fetch origin --tags")
            @systools.execute("git reset origin/#{repo[:branch]} --hard")
          end
        end
      end
    end

    def add_username(repo_url, username)
      uri = URI.parse(repo_url)
      uri.user = username
      uri.to_s
    end

    def branch_exists?(branch)
      branch = branch.gsub('.', '\\.')
      _value, exists = @systools.execute("git branch -r | grep '#{branch}$'")
      exists
    end

    def create_branch(url, branch)
      @systools.execute("git branch #{branch}")
      command = "git push origin #{branch}:#{branch}"
      puts "Run '#{command}' for repo #{url}? (y/n)"

      value = STDIN.gets.chomp.downcase
      if value == 'y'
        output, success = @systools.execute(command)
        puts "FAILED: #{output}" unless success
      end
    end

    def repos
      @repos
    end

    def release_directory
      "repos/#{@release}"
    end

    def repo_location(repo_name)
      "#{release_directory}/#{repo_name}"
    end

    def repo_names
      @repos.keys
    end

    def main_repo
      repo = @repos.find { |name, repo| repo[:main] }
      repo.nil? ? '' : repo.first
    end

    def commit_in_repo?(repo_name, hash)
      Dir.chdir(repo_location(repo_name)) do
        output, success = @systools.execute("git branch --contains #{hash}")
        success
      end
    end

    def commit_in_release_branch?(repo_names, message)
      repo_names.any? do |repo_name|
        commit_in_repo_release_branch?(repo_name, message)
      end
    end

    def git_escape(string)
      string = string.split("`")[0] if string.include?("`")
      string.gsub('"', '\"').gsub('[', '\[').gsub('*', '\*')
    end

    def commit_in_repo_release_branch?(repo_name, message)
      Dir.chdir(repo_location(repo_name)) do
        output = @systools.execute('git log --grep="' + git_escape(message.split("\n").first) + '"').first
        if output.is_a?(String)
          if output.empty?
            return false
          else
            return true
          end
        end
      end
    end

    def repository_fork(username, repo)
      url = URI.parse(repo)
      repo_name = url.path.split('/').last
      "#{url.scheme}://#{username}@#{url.host}/#{username}/#{repo_name}"
    end

  end
end
