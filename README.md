# Tools

## Release Tools

### Cherry Picks

After a release has been branched, managing what has been cherry picked and what hasn't can be time consuming. The cherry pick tool can take a given configuration, compare the repositories specified with the issues (and revisions) in Redmine and spit out what issues and revisions do not currently exist in the given release branch. To run this, you will need to have first defined a release configuration. Once you have a configuration you can run:

    ./tools.rb cherry-picks <config_file>

### Changelog Generation

This will, for a given release, generate a changelog based upon the Redmine issues for that release. The changelog is broken down by features and bug fixes. Within each of those major categories, the Redmine category for issues is used to create sections. Each section contains issues attached to that category along with the title of the issue, links to the issue in Redmine and the relevant commit hashes that introduced that story to the code base.

    ./tools changelog <config_file>

The changelog will be generated at the root of the release environment (e.g. repos/) or within a repository that is specified within the configuration having been marked as 'main'". For example:

    :repos:
      :katello:
        :main: true
        :branch: KATELLO-2.1
        :repo: https://github.com/Katello/katello.git
         

### Release Config File

The release configuration file maintains information about the release including redmine information, repositories, and branches. An example configuration file:

    ---
    :project: katello
    :release: 2.1
    :code_name: Winter Warmer
    :redmine_release_id: 14
    :repos:
      :katello:
        :main: true
        :branch: KATELLO-2.1
        :repo: https://github.com/Katello/katello.git
      :katello-installer:
        :branch: KATELLO-2.1
        :repo: https://github.com/Katello/katello-installer.git
      :hammer-cli-katello:
        :branch: 0.0.7
        :repo: https://github.com/Katello/hammer-cli-katello.git
      :katello.org:
        :branch: KATELLO-2.1
        :repo: https://github.com/Katello/katello.org.git
      :katello-agent:
        :branch: KATELLO-2.1
        :repo: https://github.com/Katello/katello-agent.git
    :ignores:
      - 7423
      - 8265
      - 7815
