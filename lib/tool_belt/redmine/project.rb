require 'date'
require File.join(File.dirname(__FILE__), 'redmine_resource')

# Issue model on the client side
module Redmine
  class Project < RedmineResource

    def base_path
      '/projects'
    end

    def versions
      get("#{@raw_data['project']['id']}/versions")
    end

    def issues_for_version(id)
      get_issues(:fixed_version_id => id, :limit => 100, :status_id => "*")
    end

    def get_issues(params = {})
      issues = get("#{@raw_data['project']['id']}/issues", params)

      if issues['offset'] + issues['limit'] < issues['total_count']
        issues = issues['issues'].concat(get_issues(params.merge(:offset => issues['offset'] + issues['limit'])))
      end

      issues.is_a?(Array) ? issues : issues['issues']
    end

    def get_issues_for_release(id)
      get_issues(:release_id => id, :limit => 100, :status_id => "5")
    end

    def trackers
      issues = get_issues(:limit => 100, :tracker_id => 6, :include => 'relations')

      issues.each do |issue|
        related_issues = issues_for_tracker(issue)
        issue['related_issues'] = related_issues
        issue.delete('relations')
      end

      issues
    end

    def issues_for_tracker(issue)
      issues = get_issues(:limit => 100, :blocks => issue['id'], :status_id => "*")
      issues.concat(get_issues(:limit => 100, :relates => issue['id'], :status_id => "*"))
      issues
    end

    def current_version
      versions = get_versions['versions']
      versions = versions.select { |version| version['due_date'] }
      versions.sort! { |a,b| a['due_date'] <=> b['due_date'] }
      versions.find do |version|
        version['status'] == 'open' && Date.parse(version['due_date']) >= Date.today
      end
    end

  end
end
