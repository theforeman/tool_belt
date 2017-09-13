require 'json'
require 'time'
require 'octokit'

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

        if commits.empty?
          pull_requests = issue['custom_fields'].find { |field| field['name'] == 'Pull request' }

          unless pull_requests.nil? || pull_requests['value'].empty?
            commits = extract_commits(pull_requests['value'])
          end
        end

        picks << cherry_pick(issue, nil) if commits.empty?

        commits.each do |commit|
          if !commit['comments'].start_with?('Merge pull request') && !@release_environment.commit_in_release_branch?(repo_names, commit['comments'])
            revisions << commit['revision']
          end
        end

        revisions.each do |revision|
          picks << cherry_pick(issue, revision)
        end

        picks << cherry_pick(issue, nil) if revisions.empty? && commits.empty?
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
    end

    def ignore?(id, revision)
      if ignores && ignores.is_a?(Hash)
        ignores.has_key?(id) && (ignores[id].nil? || ignores[id].include?(revision))
      elsif ignores
        ignores.include?(id)
      end
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

        revisions = value.select { |pick| !ignore?(pick['id'], pick['revision']) }
        revisions = revisions.collect { |pick| pick['revision'] }

        missing_string << "Pick All: git cherry-pick -x #{revisions.join(' ')}"
        missing_string << "\n"

        value.each do |pick|
          if ignore?(pick['id'], pick['revision'])
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
      "#{pick['id']} - #{Time.parse(pick['closed_on'])}: [#{pick['revision']}] #{pick['subject']}"
    end

    def find_repository(revision)
      return 'unknown' if revision == '' || revision.nil?

      @release_environment.repo_names.find do |repo_name|
        @release_environment.commit_in_repo?(repo_name, revision)
      end
    end

    def extract_commits(pull_requests)
      client = Octokit::Client.new
      revisions = pull_requests.collect do |link|
        pr = link.gsub('https://github.com/', '').split('/pull/')
        repo = pr[0]
        number = pr[1]

        pr = client.pull_request(repo, number)

        {
          'revision' => pr['merge_commit_sha'],
          'comments' => pr['title']
        }
      end

      revisions.flatten
    end

  end
end
