# Tools

## Release Tools

### Cherry Picks

After a release has been branched, managing what has been cherry picked and what hasn't can be time consuming. The cherry pick tool can take a given configuration, compare the repositories specified with the issues (and revisions) in Redmine and spit out what issues and revisions do not currently exist in the given release branch. To run this, you will need to have first defined a release configuration. Once you have a configuration you can run:

    ./tools.rb cherry-picks <config_file>

### Release Config File

The release configuration file maintains information about the release including redmine information, repositories, and branches. An example configuration file:

    ---
    :project: katello
    :release: 2.1
    :redmine_release_id: 14
    :repos:
      :katello:
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
