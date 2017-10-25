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
      self.new(
        releases: parse_releases(config.options.releases),
        prior_releases: parse_releases(config.options.prior_releases),
        namespace: config.options.namespace,
        project: config.options.project,
      )
    end

    def update_for_release
      Dir.chdir("repos/#{namespace}") do
        clone_docs_repo unless File.exist?(repo_name)
        if project == 'katello'
          Dir.chdir("#{repo_name}/plugins/katello") do
            releases.each do |release|
              unless File.exist?(release)
                if File.exist?(last_release)
                  FileUtils.copy_entry(last_release, release)
                end
              end

              docs_path = "repos/#{namespace}/#{repo_name}"
              katello_docs_path = "#{docs_path}/plugins/katello/#{release}"
              puts "Find all occurences of #{last_release} in the newly copied documentation:"
              puts
              puts "$ grep -R '#{last_release.gsub('.', '\.')}' #{katello_docs_path}"
              puts
              puts `grep -R '#{last_release.gsub('.', '\.')}' #{release}`
              puts
              puts "Update the docs at #{katello_docs_path}."
              puts "Be sure to add a link to #{release} in #{docs_path}/_layouts/plugins/katello/documentation.html."
            end
          end
        end
      end
    end

    def self.parse_releases(releases)
      releases.map do |release|
        release.first.to_s[/^\d+\.\d+/] # only take X.Y from X.Y.Z
      end
    end

    private

    def clone_docs_repo
      Git.clone("https://github.com/theforeman/#{repo_name}", repo_name)
    end

    def docs_repo
      @docs_repo ||= Git.open(repo_name, log: Logger.new(STDOUT, level: :warn))
    end

    def repo_name
      'theforeman.org'
    end

    def last_release
      @last_release ||= prior_releases.sort do |release1, release2|
        x1,y1 = release1.split('.').map(&:to_i)
        x2,y2 = release2.split('.').map(&:to_i)

        if x1 == x2
          y1 <=> y2
        else
          x1 <=> x2
        end
      end.last
    end
  end
end
