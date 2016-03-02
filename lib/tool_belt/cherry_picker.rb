require 'json'
require 'time'
require 'yaml'

require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class CherryPicker

    attr_accessor :bugzilla, :ignores, :issues, :release_environment

    def initialize(config, release_environment, issues)
      self.bugzilla = config.bugzilla || false
      self.ignores = config.ignores || []
      self.issues = issues
      self.release_environment = release_environment
      picks = find_cherry_picks(config.project, config.release, release_environment.repo_names)
      write_cherry_pick_log(picks, config.release)
    end

    def find_cherry_picks(project, release, repo_names)
      picks = []
      closed_issues = @issues.select do |issue|
        !issue['closed_on'].nil?
      end

      closed_issues.each do |issue|
        revisions = []
        commits = issue['changesets']

        commits.each do |commit|
          if commit['comments'].downcase.start_with?('fixes', 'refs') && !@release_environment.commit_in_release_branch?(repo_names, commit['comments'])
            revisions << commit['revision']
          end
        end

        revisions.each do |revision|
          picks << cherry_pick(issue, revision)
        end
      end

      picks
    end

    def cherry_pick(issue, revision)
      { 'repository' => find_repository(revision),
        'closed' => issue['closed_on'],
        'redmine' => { 'id' => issue['id'], 'subject' => issue['subject'] },
        'bugzilla' => ({ 'id' => issue['custom_fields'].select { |cf| cf['id'] == 6 }.first['value'], 'summary' => 'TBD' } if self.bugzilla),
        'commit' => revision
      }.reject{ |k,v| v.nil? }
    end

    def ignore?(id)
      ignores.include?(id) if ignores
    end

    def write_cherry_pick_log(picks, release)
      picks = picks.sort_by { |p| [p['repository'], p['closed']] }.group_by { |h| h['repository'] }.each { |k,v| v.each { |x| x.delete('repository') } }

      File.open("cherry_picks_#{release}", 'w') do |file|
        file.write(picks.to_yaml)
      end
    end

    def find_repository(revision)
      repo = @release_environment.repo_names.find { |repo_name| @release_environment.commit_in_repo?(repo_name, revision) }
      repo.nil? ? :unknown : repo
    end

  end
end
