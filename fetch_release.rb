require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'time'
require 'fileutils'

def parse_table(table, existing_ids, new_content)
  table.css("tr").each do |row|
    if cells = row.css("td")
      if cells[0]
        id = cells[0].text.chomp
        unless existing_ids.include? id
          href = cells[0].css("a").first["href"]
          subject = cells[1].text.chomp
          date = DateTime.parse(cells[4].text + "-01")
          new_content << {:id => id, :subject => subject, :href => href, :date => date}
          existing_ids << id
        end
      end
    end
  end
end

def parse_page(href, existing_ids, new_content)
  doc = Nokogiri::HTML(open("http://wikileaks.org#{href}"))
  if table = doc.css("table.cable")
    parse_table(doc, existing_ids, new_content)

    if next_link = doc.css(".pane.big a").select{|link| link.text == "Next"}.first
      parse_page(next_link["href"], existing_ids, new_content)
    end
  end
end

def parse_gifiles(existing_ids, new_content)
  doc = Nokogiri::HTML(open("http://wikileaks.org/gifiles/releasedate/2012-02-27.html"))
  doc.css(".listoflist")[1].css("a").each do |date|
    parse_page(date["href"], existing_ids, new_content)
  end
end

def load_existing_ids
  FileUtils.touch "existing_ids.md" unless File.exists? "existing_ids.md"
  file = File.open("existing_ids.md", 'r')
  return file.gets.split("-")
end

def save_existing_ids(existing_ids)
  File.open("existing_ids.md", "w"){|f| f.write existing_ids.join("-")}
end

def save_content(content)
  content.sort!{|a,b| a[:date] <=> b[:date]}
  current_date = nil
  File.open("releases/#{Time.now.strftime("%Y-%m-%d-%H%M%S")}.md", "w") do |f|
    content.each do |document|
      if current_date.nil? || current_date != document[:date]
        if document[:date].strftime("%Y-%m") == "1970-01"
          f.puts "\n# unspecified\n\n"
        else
          f.puts "\n# #{document[:date].strftime("%Y-%m")}\n\n"
        end
        current_date = document[:date]
      end
      f.puts "+ #{document[:subject]} : [#{document[:href].gsub("/gifiles/docs/","")}](http://wikileaks.org#{document[:href]})\n"
    end
  end
end

def fetch_release(forced = false)
  existing_ids = forced ? [] : load_existing_ids
  new_content = []

  parse_gifiles(existing_ids, new_content)

  if new_content.size > 0
    save_existing_ids(existing_ids)
    save_content(new_content)
  end
end

fetch_release(true)
