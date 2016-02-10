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

  def bugs_for_release(target_milestone, options = {})
    status = options.fetch(:status, ["POST"])

    # status params are case sensitive
    status = status.upcase if status.respond_to?(:upcase)
    status = status.map(&:upcase) if is_a?(Array)

    params = {
      :product => "Red Hat Satellite 6",
      :query_format => "advanced",
      :status => status,
      :include_fields => default_fields,
      :f1 => "target_milestone",
      :o1 => "equals",
      :v1 => "#{target_milestone}"
    }

    param_acc = 1

    if options[:flags]
      options[:flags].each do |flag|
        param_acc = param_acc + 1
        params.merge!({
          "f#{param_acc}".to_sym => "flagtypes.name",
          "o#{param_acc}".to_sym => flag[:option],
          "v#{param_acc}".to_sym => flag[:value]
        })
      end
    end

    params[:limit] = options.fetch(:limit, 0)
    params[:offset] = options.fetch(:offset, 0)

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
    # %w(id status severity component summary target_milestone flags comments assigned_to keywords url blocks product)
    %w(id status target_milestone flags url blocks product)
  end

end
