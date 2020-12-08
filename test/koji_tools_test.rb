require 'minitest/autorun'
require 'minitest/mock'
require 'tool_belt'
require 'mocha/minitest'

class KojiToolsTest < MiniTest::Test

  def setup
    @tools = ToolBelt::KojiTools.new
  end

  def read_data(name)
    File.open("test/data/#{name}").read
  end

  def test_get_external_repo_names
    output = read_data('list-external-repos.txt')
    @tools.expects(:koji_info).once.returns([output, true])
    assert_equal(@tools.get_external_repo_names("sometag"), ['rhel-7.0-server', 'rhel-7.0-server-optional', 'jpackage-5.0-generic-free'])
  end

  def test_build_target?
    output = read_data('tag-info-target.txt')
    @tools.expects(:koji_info).returns([output, true]).times(2)

    assert(@tools.build_target?('katello-nightly-rhel7', 'katello-nightly-rhel7-build'))
    refute(@tools.build_target?('katello-nightly-rhel7', 'katello-nightly-rhel7-notbuild'))
  end

  def test_build_target_wrong_data
    output = read_data('tag-info-build.txt')
    @tools.expects(:koji_info).returns([output, true])

    refute(@tools.build_target?('katello-nightly-rhel7', 'katello-nightly-rhel7-build'))
  end

  def test_get_inherited
    output = read_data('tag-info-build.txt')
    @tools.expects(:koji_info).returns([output, true])

    expected = {
        'katello-nightly-rhel7-override' => 0,
        'foreman-plugins-nightly-rhel7-override' => 3,
        'foreman-nightly-nonscl-rhel7' => 4,
        'katello-thirdparty-pulp-rhel7' => 5,
        'foreman-nightly-rhel7' => 10
    }

    assert_equal(@tools.get_inherited('katello-nightly-rhel7-build'), expected)
  end

  def test_packages_for_group
    output = read_data('list-groups.txt')
    @tools.expects(:koji_info).returns([output, true])

    expected = ['bash', 'bzip2', 'coreutils', 'cpio', 'diffutils', 'findutils']
    assert_equal(@tools.packages_for_group('katello-nightly-rhel7-build', 'build'), expected)
  end

end
