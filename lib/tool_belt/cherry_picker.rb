#!/usr/bin/env ruby

require 'json'
require 'time'

module ToolBelt
  class CherryPicker

    attr_accessor :ignores, :issue_cache

    def initialize(project, release, repos, redmine_release_id, ignores=[])
      self.ignores = ignores
      self.issue_cache = IssueCache.new(project, release, redmine_release_id)
      setup_repos(repos)
      picks = find_cherry_picks(project, release, repos.keys)
      write_cherry_pick_log(picks)
    end

    def load_issues
      issue_cache.load_issues
    end

    def setup_repos(repos)
      Dir.mkdir('repos') if !File.exist?('repos')

      Dir.chdir('repos') do
        repos.each do |name, repo|
          syscall("git clone #{repo[:repo]}") if !File.exist?(name.to_s)
          Dir.chdir(name.to_s) do
            syscall("git checkout #{repo[:branch]}")
          end
        end
      end
    end

    def commit_in_repos?(repos, message, issue)
      repos.any? do |repo|
        commit_in_repo?(repo, message, issue)
      end
    end

    def git_escape(string)
      string = string.split("`")[0] if string.include?("`")
      string.gsub('"', '\"').gsub('[', '\[')
    end

    def commit_in_repo?(repo, message, issue)
      Dir.chdir("repos/#{repo}") do
        output = syscall('git log --grep="' + git_escape(message.split("\n").first) + '"')
        if output.is_a?(String)
          if output.empty?
            return false
          else
            return true
          end
        end
      end
    end

    def find_cherry_picks(project, release, repos)
      picks = []
      issues = load_issues

      issues.each do |issue|
        commits = issue['changesets']

        commits.each do |commit|
          if commit['comments'].start_with?('Merge pull request')
            break
          else
            if !commit_in_repos?(repos, commit['comments'], issue)
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

    def write_cherry_pick_log(picks)
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

      File.open('cherry_picks', 'w') do |file|
        file.write(ignore_string.join("\n") + "\n\n" + missing_string.join("\n"))
      end
    end

  end
end
