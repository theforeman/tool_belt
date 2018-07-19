require File.join(File.dirname(__FILE__), 'systools')
require File.join(File.dirname(__FILE__), 'redmine/issue')

module ToolBelt
  class Changelog

    attr_accessor :issues, :bugs, :features, :release_environment, :config

    def initialize(config, release_environment)
      self.config = config
      issue_service = IssueService.new(config)

      self.features = {}
      self.bugs = {}
      self.issues = issue_service.load_issues
      self.release_environment = release_environment

      generate_entries(@issues)
      changelog = format_entries
      write_changelog(changelog, config.release, release_environment.main_repo, config.code_name)
    end

    def generate_entries(issues)
      issues.each do |issue|
        next unless issue.closed?
        next unless issue.release_id == config.redmine_release_id

        generate_entry(issue)
      end
    end

    def generate_entry(issue)
      title = issue.subject

      title_string = " * #{title} ("
      issue_string = "[##{issue.id}](https://projects.theforeman.org/issues/#{issue.id})"

      list_item = title_string
      list_item += issue_string
      list_item += ", "

      list_item += hash_string(issue)

      list_item.chop!.chop! # Remove trailing ", "
      list_item += ')'

      tracker = (issue && issue.tracker) ? issue.tracker['name'] : 'Bug'
      category = (issue && issue.category) ? issue.category['name'] : 'Other'

      if tracker == 'Bug'
        @bugs[category] = [] unless @bugs.key?(category)
        @bugs[category] << list_item
      elsif tracker == 'Feature'
        @features[category] = [] unless @features.key?(category)
        @features[category] << list_item
      end
    end

    def hash_string(issue)
      base_url = "https://github.com/#{config.github_org}"
      string = "[%{short}](#{base_url}/%{repo}/commit/%{full})"
      hashes = ""

      issue.changesets.each do |changeset|
        if changeset['comments'].start_with?('Merge pull request')
          break
        else
          short = changeset['revision'][0...8]
          full = changeset['revision']
          repo = find_repo(changeset['revision'])
          hashes += string % {:short => short, :full => full, :repo => repo}
          hashes += ', '
        end
      end

      hashes
    end

    def find_repo(message)
      @release_environment.repo_names.find do |repo_name|
        @release_environment.commit_in_repo?(repo_name, message)
      end
    end

    def format_entries
      entry_string = "\n## Features \n"
      @features.each do |category, entries|
        if category != 'Other'
          entry_string += "\n### #{category}\n"

          entries.each do |entry|
            entry_string += "#{entry}\n"
          end
        end
      end

      if @features.key?('Other')
        entry_string += "\n### Other\n"
        @features['Other'].each do |entry|
          entry_string += "#{entry}\n"
        end
      end

      entry_string += "\n## Bug Fixes \n"
      @bugs.each do |category, entries|
        if category != 'Other'
          entry_string += "\n### #{category}\n"

          entries.each do |entry|
            entry_string += "#{entry}\n"
          end
        end
      end

      if @bugs.key?('Other')
        entry_string += "\n### Other\n"
        @bugs['Other'].each do |entry|
          entry_string += "#{entry}\n"
        end
      end

      entry_string
    end

    def write_changelog(changelog, release, repo, code_name = '')
      Dir.chdir(release_environment.repo_location(repo)) do
        File.rename('CHANGELOG.md', 'CHANGELOG.md.backup') if File.exist?('CHANGELOG.md')

        File.open('CHANGELOG.md', 'w') do |file|
          file.puts("# #{release} #{code_name} (#{Date.parse(Time.now.to_s)})")
          file.write(changelog)

          if File.exist?('CHANGELOG.md.backup')
            File.open('CHANGELOG.md.backup', 'r') { |backup| file.write(backup.read) }
          end
        end

        File.delete('CHANGELOG.md.backup') if File.exist?('CHANGELOG.md.backup')
      end

      puts "Changelog is located at #{release_environment.repo_location(repo)}/CHANGELOG.md"
    end
  end
end
