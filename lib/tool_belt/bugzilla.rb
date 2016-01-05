require 'rest-client'
require 'json'

class RedHatBugzilla

  HOSTNAME = 'https://bugzilla.redhat.com/jsonrpc.cgi'

  def initialize(user, password)
    @user = user
    @password = password
  end

  def get_bug(id, fields = default_fields)
    id = [id] if !id.is_a?(Array)
    request('Bug.get', {
      :ids => id,
      :include_fields => fields
    })
  end

  def bugs_for_release(id, options = {})
    status = (options[:status] == 'closed') ? ["CLOSED"] : ["NEW", "ASSIGNED", "POST", "MODIFIED"]

    case options[:state]
    when "approved", "blocker"
      id = "#{id}+"
    when "pending"
      id = "#{id}?"
    end

    params = {
      :o1 => "substring",
      :v1 => "sat-#{id}",
      :f1 => "flagtypes.name",
      :query_format => "advanced",
      :status => status,
      :include_fields => default_fields,
      :product => "Red Hat Satellite 6"
    }

    params[:limit] = options[:limit] if !options[:limit].nil?
    params[:offset] = options[:offset] if !options[:offset].nil?

    if options[:state] == 'blocker'
      params.merge!({
        :v2 => "blocker+",
        :f2 => "flagtypes.name",
        :o2 => "substring"
      })
    end

    request("Bug.search", params)
  end

  def find_clone(id, blocker_ids)
    bugs = []

    if blocker_ids
      bugs = JSON.parse(get_bug(blocker_ids, ['id', 'cf_clone_of']))
      bugs = bugs["result"]["bugs"]

      bugs = bugs.select do |bug|
        bug['cf_clone_of'].to_s == id.to_s
      end
      bugs = bugs.collect { |bug| bug['id'] }

      get_bug(bugs.first) if !bugs.empty?
    else
      {}
    end
  end

  def request(method, params)
    params.merge!(
      :Bugzilla_login => @user,
      :Bugzilla_password => @password
    )
    params = {:params => {method: method, params: [params].to_json}}

    RestClient.get(HOSTNAME, params)
  end

  def default_fields
    %w(id status severity component summary flags comments assigned_to keywords url blocks product)
  end

end
