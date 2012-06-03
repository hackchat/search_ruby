require 'singleton'
require 'json'
require 'faraday'

module Elastic
  ELASTIC_URL = "http://localhost:9200"


  class Index
    attr_reader :index_name, :type_name, :last

    def initialize(type)
      @index_name = "#{type}-index"
      @type_name = type
      @last = 0
      add_to_elastic
    end
    
    def add_to_elastic
      index_url = URI.parse "#{ELASTIC_URL}#{index_path}/"
      Connection.new(index_url).put()
    end

    def index_path
      "/#{self.index_name}"
    end

    def search_path
      "#{type_path}/_search/"
    end

    def type_path
      "#{self.index_path}/#{type_name}/"
    end

  end

  class Database
    include Singleton
    attr_reader :connection

    def initialize
      @connection = Connection.new(ELASTIC_URL)
    end

    def indices
      @indices ||= {}
    end

    def index?(type)
      not indices[type].nil?
    end

    def get_index(type)
      self.indices[type] ||= Index.new(type)
    end

    alias :add_index :get_index

    def send_query(query)
      query.perform_query
    end

    def add_instance(type, info)
      url = self.get_index(type).type_path
      self.connection.post(url, info.to_json).inspect
    end

    def add_many_instances(type, array_of_instance_info)
      array_of_instance_info.each { |info| add_instance(type, info) }
    end

  end

  class Connection
    attr_accessor :connection

    def initialize(url = ELASTIC_URL)
      self.connection = Faraday.new(url)
    end

    def method_missing(method, *args, &block)
      self.connection.send(method, *args, block)
    end

  end

  class Query
    attr_accessor :index, :database

    def initialize(type)
      self.database = Elastic::Database.instance
      raise(ArgumentError, "Index '#{type}' not found") unless
      self.index = self.database.get_index(type)
    end

    def path
      self.index.search_path
    end

    def terms
      @terms ||= {}
    end

    def generate_query
      JSON.parse(self.to_json)
    end

    def perform_query
      response = self.database.connection.get do |request|
        request.url self.path
        request.headers['Content-Type'] = 'application/json'
        request.body(self.to_json)
      end
      response_to_results_ids_array(response)
    end

    def response_to_results_ids_array(response)
      puts "RESPONSE: \n\n #{response.inspect} \n\n"
      parsed_json = JSON.parse response.env[:body]
      puts parsed_json
      parsed_json["hits"]["hits"].inject([]) do |ids, hit|
        source = hit["_source"]
        ids << source["db_id"] if source["db_id"]
        ids
      end
    end

    def terms_to_json
      terms_array = self.terms.keys.inject([]) do |terms_array, field|
        value = self.terms[field]
        terms_array.tap do |ary|
          if value
            ary << "\"#{field}\": \"#{value}\""
          end 
        end
      end

      "{ #{terms_array.join ','} }"
    end

    def to_json
      "{ \"queryb\" : #{self.terms_to_json} }"
    end

  end

end












