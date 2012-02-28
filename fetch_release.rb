require 'rubygems'
require 'date'
require 'time'
require 'fileutils'

require './lib/models'
require './lib/parser'
require './lib/views'

def fetch_release(forced = false)
  new_content = []

  parse_gifiles(new_content)

  puts "Releases: #{new_content.size}"
  if new_content.size > 0
    create_html
  end
end

def fetch_emails
  Document.all.each do |doc|
    puts "parse_emails: #{doc.href}"
    if doc.receivers.empty?
      parse_emails(doc)
      puts "Sender: #{doc.sender.email}" if doc.sender
      puts "receivers: #{doc.receivers.size}" if doc.receivers
    end
  end
end

#fetch_release
#create_html
