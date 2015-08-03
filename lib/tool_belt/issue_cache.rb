require File.join(File.dirname(__FILE__), 'config')
require File.join(File.dirname(__FILE__), 'redmine/project')
require File.join(File.dirname(__FILE__), 'redmine/issue')

module ToolBelt
  class IssueCache

    attr_accessor :project, :release, :redmine_release_id

    def initialize(config)
      self.project = config.project
      self.release = config.release
      self.redmine_release_id = config.redmine_release_id
    end

    def add_revisions(issues)
      issues.collect do |issue, index|
        Redmine::Issue.new(issue['id'], :include => 'changesets')
      end
    end

    def load_issues(refresh=false)
      if cache_exists? && !refresh
        puts "Issues cache for #{@release} exists and was last updated on #{last_update}."
        puts "Please remove .issue_cache/#{@project}_#{@release}_issues.json if you wish to re-cache."
      else
        puts "Issues cache for #{@release} does not exist."
        puts "Loading issues from Redmine for this release and caching them at .issue_cache/#{@project}_#{@release}_issues.json"
        cache_issues
      end

      JSON.parse(File.open("./.issue_cache/#{@project}_#{@release}_issues.json", "r").read)
    end

    def cache_issues
      project = Redmine::Project.new(@project)
      issues = project.get_issues_for_release(redmine_release_id)
      issues = add_revisions(issues)

      if !File.exist?('.issue_cache')
        Dir.mkdir('.issue_cache')
      end

      File.open(cache_filename, 'w') do |file|
        file.write(JSON.dump(issues))
      end
    end

    def cache_exists?
      File.exist?(cache_filename)
    end

    def cache_filename
      ".issue_cache/#{@project}_#{@release}_issues.json"
    end

    def last_update
      Time.at(syscall("date +%s -r #{cache_filename}").first.to_i)
    end

  end
end
