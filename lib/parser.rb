require 'nokogiri'
require 'open-uri'

def parse_emails(document)
  url = "http://wikileaks.org#{document.href}"
  doc = Nokogiri::HTML(open(url))
  emails = []
  table = doc.css("table.cable:first tr")
  if from_row = table.select{|row| row.css("th").text == "From" }.map{|row| row.css("td").text.strip }.first
    document.sender = Sender.find_or_create_by_email(from_row) unless from_row.empty?
  end
  if to_row = table.select{|row| row.css("th").text == "To" }.map{|row| row.css("td").text.strip }.first
    receivers = to_row.split(", ")
    document.receivers = receivers.map{|email| Receiver.find_or_create_by_email(email)} unless receivers.empty?
  end
  document.save
end

def parse_table(table, new_content)
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
          new_content << document
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
