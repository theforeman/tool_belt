require 'octokit'
require File.join(File.dirname(__FILE__), 'redmine_resource')

# Issue model on the client side
module Redmine
  class Issue < RedmineResource

    READY_FOR_TESTING = 7
    CLOSED = ['Closed', 'Resolved', 'Rejected', 'Duplicate']

    def base_path
      '/issues'
    end

    def id
      @raw_data['issue']['id']
    end

    def changesets
      sets = @raw_data['issue']['changesets']
      return [] if sets.nil?
      sets
    end

    # arrange pull request data similar to .changesets
    def pull_request_commits
      return [] if pull_requests.nil? || pull_requests.empty?

      access_token = ENV['GITHUB_ACCESS_TOKEN']
      puts "GITHUB_ACCESS_TOKEN not present in the environment. Requests will be rate-limited." unless access_token

      client = Octokit::Client.new(access_token: access_token)
      commits = pull_requests.collect do |link|
        pr = link.gsub('https://github.com/', '').split('/pull/')
        repo = pr[0]
        number = pr[1]

        pr = client.pull_request(repo, number)

        {
          'revision' => pr['merge_commit_sha'],
          'comments' => pr['title']
        }
      end

      commits.flatten
    end

    def project
      @raw_data['issue']['project']['id']
    end

    def tracker
      @raw_data['issue']['tracker']
    end

    def category
      @raw_data['issue']['category']
    end

    def version
      @raw_data['issue']['fixed_version']['id'] if @raw_data['issue']['fixed_version']
    end

    def set_version(version_id)
      @raw_data['issue']['fixed_version_id'] = version_id
      self
    end

    def self.closed?(issue)
      CLOSED.include?(issue['status']['name'])
    end

    def closed?
      self.class.closed?(@raw_data['issue'])
    end

    def closed_on
      @raw_data['issue']['closed_on']
    end

    def subject
      @raw_data['issue']['subject']
    end

    def rejected?
      ['Rejected', 'Duplicate'].include? @raw_data['issue']['status']['name']
    end

    def set_status(status)
      @raw_data['issue']['status_id'] = status
      self
    end

    def pull_requests
      field = @raw_data['issue']['custom_fields'].find { |f| f['id'] == 7 }
      return nil if field.nil?
      field['value']
    end

    def set_pull_request(url)
      @raw_data['issue']['custom_field_values'] = {'7' => url}
      self
    end

    def save!
      put(@raw_data['issue']['id'], @raw_data)
    end

    def to_json(*args)
      @raw_data['issue'].to_json
    end
  end
end
