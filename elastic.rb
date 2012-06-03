require 'singleton'
require 'json'
require 'faraday'

module Elastic
  ELASTIC_URL = "http://localhost:9200/"


  class Index
    attr_reader :index_name, :type_name, :last

    def initialize(type)
      @index_name = "#{type}_index"
      @type_name = type
      @last = 0
      add_to_elastic
    end
    
    def add_to_elastic
      Connection.new(ELASTIC_URL + index_path).put().inspect
    end

    def index_path
      "#{self.index_name}"
    end

    def next_instance
      @last += 1
    end

    def next_instance_url
      "#{self.index_path}/#{type_name}/#{next_instance}"
    end

  end

  class Database
    include Singleton
    attr_reader :connection

    def initialize
      @connection = Connection.new(ELASTIC_URL)
    end

    def indices
      @indices ||= []
    end

    def index?(type)
      self.indices.any? do |index|
        index.type_name == type
      end
    end

    def find_or_add_index(type)
      get_index(type) || add_index(type)
    end

    def get_index(type)
      self.indices.select { |i| i.type_name == type }.first
    end

    def add_index(type)
      Index.new(type).tap {|i| self.indices << i }
    end

    def add_instance(type, info)
      url = find_or_add_index(type).next_instance_url
      self.connection.get(url)
      url =~ /\/(\d+)[\/]?/
      id = $1
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

end