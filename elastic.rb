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
    end
    
    def index_url
      "#{self.index_name}/#{self.type_name}/"
    end

    def next_instance
      @last += 1
    end

    def next_instance_url
      "#{self.index_url}/#{next_instance}"
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

    def add_index(type)
      self.indices << Index.new(type)
    end

    def add_instance(type, info)
      index = find_index_by_type(type)
      self.connection.get index.next_instance_url
    end

    def add_many_instances(type, array_of_instance_info)
      array_of_instance_info.each { |info| add_instance(type, info) }
    end

  end

  class Connection
    attr_accessor :connection  

    def initialize(url)
      self.connection = Faraday.new(ELASTIC_URL)
    end

    def method_missing(method, *args, &block)
      self.connection.send(method, *args, block)
    end

  end

end