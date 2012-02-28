require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'time'
require 'fileutils'
require 'redcarpet/compat'
require 'mongo_mapper'
require 'erb'

MongoMapper.database = 'wikileaks_stratfor'

class Document
  include MongoMapper::Document

  key :wikileaks_id, String
  key :subject, String
  key :href, String
  key :date, Time

  belongs_to :pool

  timestamps!
end


class Pool
  include MongoMapper::Document

  many :documents

  timestamps!
end

def parse_table(table, new_content)
  table.css("tr").each do |row|
    if cells = row.css("td")
      if cells[0]
        id = cells[0].text.chomp
        unless Document.find_by_wikileaks_id(id)
          href = cells[0].css("a").first["href"]
          subject = cells[1].text.chomp
          date = DateTime.parse(cells[4].text + "-01")
          new_content << Document.create(
            :wikileaks_id => id,
            :subject => subject,
            :href => href,
            :date => date
          )
        end
      end
    end
  end
end

def parse_page(href, new_content)
  doc = Nokogiri::HTML(open("http://wikileaks.org#{href}"))
  if table = doc.css("table.cable")
    parse_table(doc, new_content)

    if next_link = doc.css(".pane.big a").select{|link| link.text == "Next"}.first
      parse_page(next_link["href"], new_content)
    end
  end
end

def parse_gifiles(new_content)
  doc = Nokogiri::HTML(open("http://wikileaks.org/gifiles/releasedate/2012-02-27.html"))
  doc.css(".listoflist")[1].css("a").each do |date|
    parse_page(date["href"], new_content)
    unless new_content.empty?
      pool = Pool.new
      pool.documents = new_content
      pool.save
    end
  end
end

def stats_data(documents)
  data = {}
  documents.each do |document|
    if data[document.date.strftime("%Y-%m")]
      data[document.date.strftime("%Y-%m")] += 1
    else
      data[document.date.strftime("%Y-%m")] = 1
    end
  end
  return data.to_a.map{|d| {:y => d[0], :a => d[1]}}.to_json
end

def create_index
  pools = Pool.all(:order => :created_at.desc)
  content = "<ul>"
  pools.each do |pool|
    creation_date = pool.created_at.strftime("%d-%m-%Y_at_%H:%M")
    content << "<li><a href='#{creation_date}.html'>#{creation_date}</a> : #{pool.documents.size} documents</li>"
  end
  morris_data = stats_data(Document.where(:date.gte => 20.years.ago).sort(:date.desc))
  erb = ERB.new(File.read("views/layout.erb"))
  File.open("_site/index.html", "w"){|f| f.write(erb.result(binding))}
end

def create_pools
  erb = ERB.new(File.read("views/layout.erb"))
  Pool.all.each do |pool|
    content = ""
    creation_date = pool.created_at.strftime("%d-%m-%Y_at_%H:%M")
    current_date = nil
    closing = false
    morris_data = stats_data(pool.documents.where(:date.gte => 20.years.ago).sort(:date.desc))
    pool.documents.all(:order => :date.asc).each do |document|
      if current_date.nil? || current_date != document.date
        content += "</ul>" if closing
        if document.date.strftime("%Y-%m") == "1970-01"
          content += "<h3>unspecified</h3>"
        else
          content += "<h3>#{document.date.strftime("%Y-%m")}</h3>"
        end
        current_date = document.date
        content += "<ul>"
        closing = true
      end
      content += "<li>#{document.subject} : <a href='http://wikileaks.org#{document.href}'>#{document.href.gsub("/gifiles/docs/","")}</a></li>"
    end
    content += "</ul>"
    File.open("_site/#{creation_date}.html", "w"){|f| f.write(erb.result(binding))}
  end
end

def create_html
  create_index
  create_pools
end

def fetch_release(forced = false)
  new_content = []

  parse_gifiles(new_content)

  p new_content.size
  if new_content.size > 0
    create_html
  end
end

#fetch_release
create_html
