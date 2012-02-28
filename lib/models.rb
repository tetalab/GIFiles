require 'mongo_mapper'

MongoMapper.database = 'wikileaks_stratfor'

class Document
  include MongoMapper::Document

  key :wikileaks_id, String
  key :subject, String
  key :href, String
  key :date, Time
  #key :email_ids, Array

  #one :sender, :in => :email_ids
  #many :receivers, :in => :emails_ids

  belongs_to :pool

  timestamps!
end

class Email
  include MongoMapper::Document

  key :label, String

  timestamps!
end

class Pool
  include MongoMapper::Document

  many :documents

  timestamps!
end
