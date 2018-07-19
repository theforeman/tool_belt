require File.join(File.dirname(__FILE__), 'redmine/project')

module ToolBelt
  # Find issues for a particular project & release
  class IssueService
    attr_accessor :project_name, :release, :redmine_version_id, :prior_releases

    def initialize(config)
      self.project_name = config.project
      self.release = config.release
      self.redmine_version_id = config.redmine_version_id
      self.prior_releases = config.prior_releases || []
    end

    def project
      @project ||= Redmine::Project.new(project_name)
    end

    def release_issues(version_id)
      project.issues_for_version(version_id)
    end

    def load_issues
      issues = release_issues(redmine_version_id)

      prior_releases.each do |_version, meta|
        issues.concat(release_issues(meta[:redmine_version_id]))
      end

      issue_ids = issues.collect { |issue| issue['id'] }.uniq.compact
      issue_ids.collect do |id|
        Redmine::Issue.new(id, include: 'changesets')
      end
    end
  end
end
