# Tools

## Release Tools

### Cherry Picks

After a release has been branched, managing what has been cherry picked and what hasn't can be time consuming. The cherry pick tool can take a given configuration, compare the repositories specified with the issues (and revisions) in Redmine and spit out what issues and revisions do not currently exist in the given release branch. To run this, you will need to have first defined a release configuration. Once you have a configuration you can run:

    ./tools.rb cherry-picks <config_file>

