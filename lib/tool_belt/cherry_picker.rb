require 'json'
require 'time'

require File.join(File.dirname(__FILE__), 'systools')
require File.join(File.dirname(__FILE__), 'issue_cache')

module ToolBelt
  class CherryPicker

    attr_accessor :ignores, :issue_cache, :release_environment

    def initialize(config, release_environment)
      self.ignores = config.ignores || []
      self.issue_cache = IssueCache.new(config)
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
      issues = issues.select { |issue| !issue['closed_on'].nil? }

      issues.each do |issue|
        revisions = []
        commits = issue['changesets']

        commits.each do |commit|
          if !commit['comments'].start_with?('Merge pull request') && !@release_environment.commit_in_repos?(repo_names, commit['comments'])
            revisions << commit['revision']
          end
        end

        picks << cherry_pick(issue, revisions) unless revisions.empty?
      end

      picks
    end

    def cherry_pick(issue, revisions)
      {
        'id' => issue['id'],
        'closed_on' => issue['closed_on'],
        'subject' => issue['subject'],
        'revisions' => revisions
      }
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
          ignore_string << "#{pick['id']} - #{Time.parse(pick['closed_on'])}: #{pick['revisions']} #{pick['subject']}"
        else
          missing_string << "#{pick['id']} - #{Time.parse(pick['closed_on'])}: #{pick['revisions']} #{pick['subject']}"
        end
      end

      File.open("cherry_picks_#{release}", 'w') do |file|
        file.write(ignore_string.join("\n") + "\n\n" + missing_string.join("\n"))
      end

      puts "Cherry picks written to cherry_picks_#{release}"
    end

  end
end
