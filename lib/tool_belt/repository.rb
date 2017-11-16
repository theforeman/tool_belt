require 'git'

module ToolBelt
  class Repository

    attr_reader :name, :branch, :url, :version_branch, :main, :options

    def initialize(name, args = {}, options = {})
      @name = name
      @branch = args[:branch]
      @url = args[:repo]
      @version_branch = args[:version_branch]
      @main = args[:main]
      @options = options
    end

    def self.parse(config)
      config.options.repos.map do |repo|
        self.new(*repo, namespace: config.options.namespace)
      end
    end

    def tag_exists?(tag)
      return git.tags.any? { |r| r.name == tag}
    end

    def create_or_checkout_branch
      git.checkout('origin/HEAD')
      git.reset_hard('origin/HEAD')

      if git.branches[origin_branch] || tag_exists?(origin_branch)
        git.checkout(origin_branch)
      elsif git.branches[branch] || tag_exists?(branch)
        create_origin_branch
      else
        create_local_branch
      end
    end

    def path
      "repos/#{options[:namespace]}/#{name}"
    end

    private

    def git
      @git ||= Git.open(path, log: Logger.new(STDOUT, level: :warn))
    end

    def origin_branch
      "origin/#{branch}"
    end

    def create_origin_branch
      git.checkout(branch)
      puts "Push #{branch_or_tag} #{branch} to repo #{url}? (y/n)"
      return unless STDIN.gets.chomp.downcase == 'y'
      git.push('origin', branch)
    end

    def create_local_branch
      puts "Create #{branch_or_tag} #{branch} in repo #{name}? (y/n)"
      return unless STDIN.gets.chomp.downcase == 'y'
      git.branch(branch).checkout
    end

    def branch_or_tag
      version_branch ? "branch" : "tag"
    end
  end
end
