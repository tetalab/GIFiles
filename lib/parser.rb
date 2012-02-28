require 'nokogiri'
require 'open-uri'

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
