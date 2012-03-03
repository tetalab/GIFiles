require 'mongo_mapper'

MongoMapper.database = 'wikileaks_stratfor'

class Document
  include MongoMapper::Document

  key :wikileaks_id, String
  key :subject, String
  key :href, String
  key :date, Time
  key :exact_date, Time
  key :sender, String
  key :receivers, Array

  belongs_to :pool

  timestamps!
end

class Pool
  include MongoMapper::Document
  many :documents
  timestamps!
end
