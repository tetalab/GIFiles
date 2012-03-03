require 'nokogiri'
require 'open-uri'

def parse_date(document, table)
  if date_row = table.select{|row| row.css("th").text == "Date" }.map{|row| row.css("td").text.strip }.first
    unless date_row.empty? || date_row == "1970-01-01 01:00:00"
      document.exact_date = DateTime.parse date_row
      document.save
    end
  end
end

def parse_from(document, table)
  if from_row = table.select{|row| row.css("th").text == "From" }.map{|row| row.css("td").text.strip }.first
    unless from_row.empty?
      document.sender = from_row
      document.save
    end
  end
end

def parse_to(document, table)
  if to_row = table.select{|row| row.css("th").text == "To" }.map{|row| row.css("td").text.strip }.first
    receivers = to_row.split(", ")
    unless receivers.empty?
      document.receivers = receivers
      document.save
    end
  end
end

def parse_emails(document)
  filename = File.join("/Users/alx/code/gifiles-20120228225324/", document.href)
  if File.exists? filename
    doc = Nokogiri::HTML(open(filename))
  else
    url = "http://wikileaks.org#{document.href}"
    doc = Nokogiri::HTML(open(url))
  end
  table = doc.css("table.cable:first tr")
  parse_date(document, table)
  parse_from(document, table)
  parse_to(document, table)
end

def parse_table(table)
  documents = []
  table.css("tr").each do |row|
    if cells = row.css("td")
      if cells[0]
        id = cells[0].text.strip
        unless Document.find_by_wikileaks_id(id)
          href = cells[0].css("a").first["href"]
          subject = cells[1].text.strip
          date = DateTime.parse(cells[4].text + "-01")
          document = Document.create(
            :wikileaks_id => id,
            :subject => subject,
            :href => href,
            :date => date
          )
          parse_emails(document)
          documents << document
        end
      end
    end
  end
  return documents
end

def parse_page(href)
  documents = []
  doc = Nokogiri::HTML(open("http://wikileaks.org#{href}"))
  if table = doc.css("table.cable")
    documents |= parse_table(doc)

    if next_link = doc.css(".pane.big a").select{|link| link.text == "Next"}.first
      documents |= parse_page(next_link["href"])
    end
  end
  return documents
end

def parse_gifiles
  documents = []
  doc = Nokogiri::HTML(open("http://wikileaks.org/gifiles/releasedate/2012-02-27.html"))
  doc.css(".listoflist")[1].css("a").each do |date|
    documents |= parse_page(date["href"])
  end
  return documents
end
