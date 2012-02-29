require 'mongo_mapper'

MongoMapper.database = 'wikileaks_stratfor'

class Document
  include MongoMapper::Document

  key :wikileaks_id, String
  key :subject, String
  key :href, String
  key :date, Time

  one :sender
  many :receivers

  belongs_to :pool

  timestamps!
end

class Email
  include MongoMapper::Document
  key :email, String
  key :document_ids, Array
  many :documents, :in => :document_ids
  timestamps!
end

class Sender < Email
end

class Receiver < Email
end

class Pool
  include MongoMapper::Document

  many :documents

  timestamps!
end
