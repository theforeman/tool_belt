require File.join(File.dirname(__FILE__), 'systools')
require File.join(File.dirname(__FILE__), 'redmine/issue')

module ToolBelt
  class Changelog

    attr_accessor :issues, :bugs, :features, :release_environment, :config

    def initialize(config, release_environment, issues)
      self.config = config
      self.features = {}
      self.bugs = {}
      self.issues = issues
      self.release_environment = release_environment

      generate_entries(@issues)
      changelog = format_entries
      releases = config.releases.keys.map { |key| key.to_s }
      minor_release = releases.sort_by { |v| v.split('.').map(&:to_i) }.last
      write_changelog(changelog, minor_release, release_environment.main_repo, config.code_name)
    end

    def generate_entries(issues)
      issues.select(&:closed?).each do |issue|
        generate_entry(issue)
      end
    end

    def generate_entry(issue)
      links = ["[##{issue.id}](#{issue.html_url})"] + commit_urls(issue)
      list_item = " * #{issue.subject} (#{links.join(', ')})"

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

    def commit_urls(issue)
      urls = []

      issue.changesets.each do |changeset|
        break if changeset['comments'].start_with?('Merge pull request')

        commit = changeset['revision']

        repo_name = @release_environment.repo_names.find do |name|
          @release_environment.commit_in_repo?(name, commit)
        end

        if repo_name
          url = "#{@release_environment.repos[repo_name][:repo]}/commit/#{commit}"
          urls << "[#{changeset['revision'][0...8]}](#{url})"
        else
          puts "Repo for commit #{commit} from #{issue.id} not found"
        end
      end

      urls
    end

    def format_entries
      entry_string = ''

      unless @features.empty?
        entry_string += "\n## Features\n"

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
      end

      entry_string += "\n## Bug Fixes\n"
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
          if code_name
            file.puts("# #{release} #{code_name} (#{Date.today.to_s})")
          else
            file.puts("# #{release} (#{Date.today.to_s})")
          end
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
