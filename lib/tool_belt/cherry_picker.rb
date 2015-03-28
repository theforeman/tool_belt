require 'json'
require 'time'

require File.join(File.dirname(__FILE__), 'systools')
require File.join(File.dirname(__FILE__), 'issue_cache')

module ToolBelt
  class CherryPicker

    attr_accessor :ignores, :issue_cache, :release_environment

    def initialize(config, release_environment)
      self.ignores = config.ignores || []
      self.issue_cache = IssueCache.new(config.project, config.release, config.redmine_release_id)
      self.release_environment = release_environment
      picks = find_cherry_picks(config.project, config.release, release_environment.repo_names)
      write_cherry_pick_log(picks, config.release)
    end

    def load_issues
      issue_cache.load_issues
    end

    def find_cherry_picks(project, release, repo_names)
      picks = []
      issues = load_issues

      issues.each do |issue|
        commits = issue['changesets']

        commits.each do |commit|
          if commit['comments'].start_with?('Merge pull request')
            break
          else
            if !@release_environment.commit_in_repos?(repo_names, commit['comments'])
              picks << issue
            end
          end
        end
      end

      picks
    end

    def revisions(issue)
      revisions = []

      issue['changesets'].each do |commit|
        if !commit['comments'].start_with?('Merge pull request')
          revisions << commit['revision']
        end
      end

      revisions
    end

    def ignore?(id)
      ignores.include?(id) if ignores
    end

    def write_cherry_pick_log(picks, release)
      picks.sort_by! { |pick| pick['closed_on'] }

      ignore_string = ["Ignored Cherry Picks\n====================="]
      missing_string = ["Missing Cherry Picks\n===================="]

      picks.each do |pick|
        if ignore?(pick['id'])
          ignore_string << "#{pick['id']} - #{Time.parse(pick['closed_on'])}: #{revisions(pick)} #{pick['subject']}"
        else
          missing_string << "#{pick['id']} - #{Time.parse(pick['closed_on'])}: #{revisions(pick)} #{pick['subject']}"
        end
      end

      File.open("cherry_picks_#{release}", 'w') do |file|
        file.write(ignore_string.join("\n") + "\n\n" + missing_string.join("\n"))
      end

      puts "Cherry picks written to cherry_picks_#{release}"
    end

  end
end
