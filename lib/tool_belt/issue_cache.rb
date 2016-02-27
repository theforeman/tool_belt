require 'fileutils'
require 'yaml'

require File.join(File.dirname(__FILE__), 'config')
require File.join(File.dirname(__FILE__), 'redmine/project')
require File.join(File.dirname(__FILE__), 'redmine/issue')

module ToolBelt
  class IssueCache

    attr_accessor :project, :release, :redmine_release_id, :systools

    def initialize(config)
      self.project = config.project
      self.release = config.release
      self.redmine_release_id = config.redmine_release_id
      self.systools = SysTools.new
    end

    def add_revisions(id)
      Redmine::Issue.new(id, :include => 'changesets')
    end

    def load_issues(refresh=false)
      if !cache_exists? || refresh
        puts "Refreshing issues for #{@project}_#{@release}"
        cache_issues
      end

      release_manifest[:issues].collect do |id|
        JSON.parse(File.open("#{issue_cache}/#{id}.json").read)
      end
    end

    def cache_issues
      project = Redmine::Project.new(@project)

      FileUtils.mkdir_p(issue_cache) unless File.exist?(issue_cache)
      FileUtils.mkdir_p(release_cache) unless File.exist?(release_cache)

      cache_manifest = if cache_exists?
                        release_manifest
                       else
                        {release: redmine_release_id, project: @project, issues: []}
                       end

      issues = project.get_issues_for_release(redmine_release_id)
      issue_ids = issues.collect { |issue| issue['id'] } - release_manifest[:issues]

      issue_ids.each do |id|
        issue = add_revisions(id)

        File.open("#{issue_cache}/#{issue.id}.json", 'w') do |file|
          file.write(JSON.dump(issue))
          cache_manifest[:issues] << issue.id
        end
      end

      File.open(cache_filename, 'w') do |file|
        file.write(cache_manifest.to_yaml)
      end
    end

    def cache_exists?
      File.exist?(cache_filename)
    end

    def release_manifest
      YAML.load_file(cache_filename)
    end

    def issue_cache
      '.cache/issues'
    end

    def release_cache
      '.cache/releases'
    end

    def cache_filename
      "#{release_cache}/#{@project}_#{@release}_issues.yaml"
    end

    def last_update
      Time.at(systools.execute("date +%s -r #{cache_filename}").first.to_i)
    end

  end
end
