require 'json'
require 'time'

require File.join(File.dirname(__FILE__), 'systools')

module ToolBelt
  class CherryPicker

    attr_accessor :ignores, :issues, :release_environment

    def initialize(config, release_environment, issues)
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
          if commit['comments'].downcase.start_with?('fixes') && !@release_environment.commit_in_release_branch?(repo_names, commit['comments'])
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
      pick = {
        'id' => issue['id'],
        'closed_on' => issue['closed_on'],
        'subject' => issue['subject'],
        'revision' => revision,
        'repository' => find_repository(revision)
      }
      pick.merge({'bugzilla_id' => issue['bugzilla_id']}) if issue['bugzilla_id']
    end

    def ignore?(id)
      ignores.include?(id) if ignores
    end

    def write_cherry_pick_log(picks, release)
      picks.sort_by! { |pick| pick['closed_on'] }

      picks_by_repository = {'unknown' => []}

      picks.each do |pick|
        if pick['repository'].nil?
          picks_by_repository['unknown'] << pick
        else
          picks_by_repository[pick['repository']] = [] unless picks_by_repository.key?(pick['repository'])
          picks_by_repository[pick['repository']] << pick
        end
      end

      ignore_string = ["Ignored Cherry Picks\n====================="]
      missing_string = ["Missing Cherry Picks\n===================="]

      picks_by_repository.each do |key, value|
        missing_string << "\nCherry Picks for repository: #{key}"
        missing_string << "----------------------------------------------"

        value.each do |pick|
          if ignore?(pick['id'])
            ignore_string << log_entry(pick)
          else
            missing_string << log_entry(pick)
          end
        end
      end

      File.open("cherry_picks_#{release}", 'w') do |file|
        file.write(ignore_string.join("\n") + "\n\n" + missing_string.join("\n"))
      end

      puts "Cherry picks written to cherry_picks_#{release}"
    end

    def log_entry(pick)
      if pick['bugzilla_id']
        "#{pick['bugzilla_id']} - #{pick['id']} : [#{pick['revision']}] #{pick['subject']}"
      else
        "#{pick['id']} - #{Time.parse(pick['closed_on'])}: [#{pick['revision']}] #{pick['subject']}"
      end
    end

    def find_repository(revision)
      @release_environment.repo_names.find do |repo_name|
        @release_environment.commit_in_repo?(repo_name, revision)
      end
    end

  end
end
