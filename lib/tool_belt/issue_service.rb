require File.join(File.dirname(__FILE__), 'redmine/project')

module ToolBelt
  # Find issues for a particular project & release
  class IssueService
    attr_accessor :project_name, :release, :redmine_version_id, :prior_releases, :version_priors

    def initialize(config)
      self.project_name = config.project
      self.release = config.release
      self.redmine_version_id = config.redmine_version_id
      self.prior_releases = config.send(:"prior-releases") || []
      self.version_priors = config.releases.dig(:"#{release}", :prior_release) || []
    end

    def project
      @project ||= Redmine::Project.new(project_name)
    end

    def release_issues(version_id)
      project.issues_for_version(version_id)
    end

    def load_issues(with_all_priors: false, with_version_priors: false)
      issues = release_issues(redmine_version_id)

      if with_version_priors
        # when creating a changelog to include only the relevant prior versions
        version_priors.each do |prior_version|
          prior = prior_releases[:"#{prior_version}"]
          fail("Prior version #{prior_version} was not configured for #{release}") unless prior

          issues.concat(release_issues(prior[:redmine_version_id]))
        end
      elsif with_all_priors
        # when cherry-picking to make sure nothing is missed
        prior_releases.each do |_version, meta|
          issues.concat(release_issues(meta[:redmine_version_id]))
        end
      end

      issue_ids = issues.collect { |issue| issue['id'] }.uniq.compact
      issue_ids.collect do |id|
        Redmine::Issue.new(id, include: 'changesets')
      end
    end
  end
end
