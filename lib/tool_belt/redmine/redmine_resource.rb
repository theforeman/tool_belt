require 'rubygems'
require 'json'
require 'rest_client'

# Issue model on the client side
class RedmineResource

  attr_reader :resource
  attr_accessor :base_path, :raw_data

  def initialize(path = nil, params = {})
    site = 'https://projects.theforeman.org'
    key = ENV['REDMINE_API_KEY']

    options = {}
    options[:headers] = {'X-Redmine-API-Key' => key} if key

    @resource = RestClient::Resource.new(site, options)
    self.raw_data = get(path, params) unless path.nil?
  end

  def base_path
    '/'
  end

  def get(path = nil, params = {})
    JSON.parse(@resource[format_path(path)].get(params: params))
  end

  def post(path, payload)
    @resource[format_path(path)].post(payload)
  end

  def put(path, payload)
    @resource[format_path(path)].put(payload)
  end

  def delete(path)
    @resource[format_path(path)].delete
  end

  def format_path(path)
    path ? "#{base_path}/#{path}.json" : "#{base_path}.json"
  end

end
