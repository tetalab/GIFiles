require 'rubygems'
require 'date'
require 'time'
require 'fileutils'

require './lib/models'
require './lib/parser'
require './lib/views'

def fetch_release(forced = false)
  new_content = []

  current_count = Document.count

  doc = Nokogiri::HTML(open("http://wikileaks.org/gifiles/releasedate/2012-02-27.html"))
  remote_count = doc.css("div.pane.small").text.scan(/\d+/).first.to_i

  if current_count != remote_count
    pool = Pool.create(:documents => parse_gifiles)
    puts "Mail released: #{pool.documents.count}"
    create_html
  end
end

def fetch_emails
  Document.all.each do |doc|
    puts "parse_emails: #{doc.href}"
    if doc.receivers.empty?
      parse_emails(doc)
      puts "Sender: #{doc.sender}" if doc.sender
      puts "receivers: #{doc.receivers.size}" if doc.receivers
    end
  end
end

fetch_release
#create_html
#fetch_emails
