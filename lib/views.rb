require 'erb'

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

def pool_list
  pools = Pool.all(:order => :created_at.desc)
  content = "<ul>"
  pools.each do |pool|
    creation_date = pool.created_at.strftime("%d-%m-%Y_at_%H:%M")
    content << "<li><a href='#{creation_date}.html'>#{creation_date}</a> : #{pool.documents.size} documents</li>"
  end
  return content
end

def create_index
  content = pool_list
  morris_data = stats_data(Document.where(:date.gte => 20.years.ago).sort(:date.desc))
  erb = ERB.new(File.read("layouts/index.erb"))
  File.open("_site/index.html", "w"){|f| f.write(erb.result(binding))}
end

def create_pools
  erb = ERB.new(File.read("layouts/pool.erb"))
  menu = pool_list
  Pool.all.each do |pool|
    content = "<p>Released at #{pool.created_at.strftime("%H:%M on %d/%m/%Y")} - #{pool.documents.size} documents"
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
      content += "<li>#{document.subject} [<a href='http://wikileaks.org#{document.href}'>Read</a>]</li>"
    end
    content += "</ul>"
    File.open("_site/#{creation_date}.html", "w"){|f| f.write(erb.result(binding))}
  end
end

def create_html
  create_index
  create_pools
end
