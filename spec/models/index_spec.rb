require './elastic'
require 'faker'

SEARCH_URL = 'localhost:9200'

describe Elastic::Index do
  let(:type) { Faker::Name.first_name }
  subject { Elastic::Index.new(type) }

  it "generates an index on creation" do
    subject.index_name.should match /-index$/
  end
end