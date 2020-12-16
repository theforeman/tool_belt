require 'git'

module ToolBelt
  class DocsRepository

    attr_reader :releases, :prior_releases, :namespace, :project

    def initialize(args = {})
      @releases = args[:releases]
      @prior_releases = args[:prior_releases]
      @namespace = args[:namespace]
      @project = args[:project]
    end

    def self.parse(config)
      new(
        releases: parse_releases(config.options.releases),
        prior_releases: parse_releases(config.options.prior_releases),
        namespace: config.options.namespace,
        project: config.options.project
      )
    end

    def self.parse_releases(releases)
      releases.map do |release|
        release.first.to_s[/^\d+\.\d+/] # only take X.Y from X.Y.Z
      end
    end

    def release
      releases.first
    end

    def source_release
      'nightly'
    end

    def update_for_release
      Dir.chdir("repos/#{namespace}") do
        clone_docs_repo unless File.exist?(repo_name)

        katello_includes_path = "#{repo_name}/_includes/plugins/katello"

        # copy sidebar
        Dir.chdir(katello_includes_path) do
          release_sidebar = "sidebar_#{release}.html"
          unless File.exist?(release_sidebar)
            sidebar = "sidebar_#{source_release}.html"
            if File.exist?(sidebar)
              FileUtils.copy_entry(sidebar, release_sidebar)
            end
          end
        end

        Dir.chdir("#{repo_name}/plugins/katello") do
          unless File.exist?(release)
            if File.exist?(source_release)
              FileUtils.copy_entry(source_release, release)
            end
          end
        end

        docs_repo_path = "repos/#{namespace}/#{repo_name}"
        katello_docs_path = "#{docs_repo_path}/plugins/katello/#{release}"

        puts "Find all occurences of #{source_release} in the newly copied documentation:"
        puts
        puts "$ grep -R '#{source_release.gsub('.', '\.')}' #{katello_docs_path}"
        puts
        puts `pwd`
        puts `grep -R '#{source_release.gsub('.', '\.')}' #{repo_name}/plugins/katello/#{release}`
        puts
        puts "Don't forget to:"
        puts " - Review the docs at #{katello_docs_path} for correctness"
        puts " - Include latest API docs per tool_belt branch procedure #{katello_docs_path}"
      end
    end

    private

    def clone_docs_repo
      Git.clone("https://github.com/theforeman/#{repo_name}", repo_name)
    end

    def repo_name
      'theforeman.org'
    end
  end
end
