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

fetch_release
#create_html
