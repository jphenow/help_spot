require 'uri'
require 'net/http'
require 'json'
require 'yaml'

##
# help_spot
#
# A partial basic implementation of a HelpSpot API interface
#
# == Using help_spot
#
# === Basics
#
# Copy and edit the included config file. Include the gem in your app. Call the configure method. Hit the API.
#
#   require 'help_spot'
#   HelpSpot.configure(:app_root => '/my_app/')
#   HelpSpot.forums_list
#
#   => [{"xForumId"=>"1", "fClosed"=>"0", "sForumName"=>"The First Forum", "iOrder"=>"0", "sDescription"=>"A test forum"}, {"xForumId"=>"2", "fClosed"=>"0", "sForumName"=>"Secondary Forum", "iOrder"=>"0", "sDescription"=>"Forum #2"}]
#

module HelpSpot
  class << self

    # Loads the config file.
    # 
    # == Options
    # * app_root (optional)
    #     Path to the root directory of your app. Shouldn't be required when using merb or Rails.
    # * config_file (optional)
    #     Defaults to '/config/help_spot.yml'
    #
    def configure(args={})    
      # work out the default app_root
      app_root = args[:app_root] || '.'
      
      config_file = args[:config_file] || '/config/help_spot.yml'
      yml_file    = app_root+config_file
      
      raise yml_file+" not found" unless File.exist? yml_file
      @config = YAML.load(File.open yml_file)
      @config["api_url"] = @config["root_url"] + "/api/index.php?output=json"
    end

    def root_url
      @config["root_url"]
    end

    def get_request(request_id)
      JSON.parse(api_request('private.request.get', 'GET', {:xRequest => request_id})) if request_id
    end

    def get_changed(time, category)
      requests = []
      req_ids = JSON.parse(api_request('private.request.getChanged', 'GET', {:dtGMTChange => time.to_i}))["xRequest"]
      req_ids.uniq!
      req_ids.each do |req_id|
        request = get_request(req_id)
        requests << request if request["xCategory"] == category
      end
      requests
    end

    def get_custom_fields(category=nil)
      JSON.parse(api_request('private.request.getCustomFields', 'GET', {:xCategory => category}))["field"]
    end

    def get_categories(category=nil)
      JSON.parse(api_request('request.getCategories', 'GET'))["category"]
    end

    def categories(args={})
      res = api_request('private.request.getCategories', 'GET')
      res = JSON.parse(res)['category'] rescue []

      unless args[:include_deleted] and args[:include_deleted] == true
        res.reject!{|k, v| v['fDeleted'] == '1'} rescue []
      end
      
      return res
    end

    def update_request(options)
      JSON.parse(api_request('private.request.update', 'POST', options))
    end
    
    def api_request(api_method, http_method='POST', args={})
      api_params =  {:method => api_method, :output => 'json'}.merge(args)
      query_params = api_params.collect{|k,v| [k.to_s, v.to_s]} # [URI.encode(k.to_s),URI.encode(v.to_s.gsub(/\ /, '+'))]
      built_query  = query_params.collect{|i| i.join('=')}.join('&') # make a query string
  
      ru = URI::parse(@config['api_url']) # where ru = ROOT_URL
      merged_query = [built_query, (ru.query == '' ? nil : ru.query)].compact.join('&') # merge our generated query string with the ROOT_URL's query string
  
      url = URI::HTTP.new(ru.scheme, ru.userinfo, ru.host, ru.port, ru.registry, ru.path, ru.opaque, merged_query, ru.fragment)
  
      if http_method == 'POST'
        req = Net::HTTP::Post.new(url.path)
        req.set_form_data(query_params)
        req.basic_auth @config['username'], @config['password']
        res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      else
        req = Net::HTTP::Get.new(url.path+'?'+url.query)
        req.basic_auth @config['username'], @config['password']
        res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }
      end

      res.body
    end
      
  end # class
end # module
