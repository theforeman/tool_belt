require 'minitest/autorun'
require 'minitest/mock'
require 'tool_belt'
require 'mocha/minitest'

class ChangelogTest < MiniTest::Test

  def setup
    issue = Redmine::Issue.new
    issue.raw_data = {
      'issue' => {
        'status' => {
          'name'=> 'Closed'
        },
        'tracker' => {
          'name' => "Feature"
        }
      }
    }

    @issues = [
      issue
      ]

    @config = mock('release')
    @config.stubs(:release).returns('v1.0')
    @config.stubs(:code_name).returns('atest')

    @env = mock('release_environment')
    @env.stubs(:main_repo).returns('arepo')
    @env.stubs(:repo_location).returns('someurl')

    ToolBelt::Changelog.any_instance.stubs(:write_changelog)
  end

  def test_generates_features_heading_when_features_are_not_empty
    changelog = ToolBelt::Changelog.new(@config, @env, @issues)
    entries_string = changelog.format_entries

    assert entries_string.include? "Features"
  end

  def test_skips_features_heading_when_features_is_empty
    changelog = ToolBelt::Changelog.new(@config, @env, [])
    entries_string = changelog.format_entries

    refute entries_string.include? "Features"
  end
end
