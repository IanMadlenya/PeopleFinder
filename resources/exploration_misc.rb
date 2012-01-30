li_users = db.collection('linkedin_users')
li_users.create_index('permalink')

ll.keys.each do |pl|
  profile = people.find_one({:permalink => pl},:fields =>['revisions'])['revisions'].first.last
  begin
    li_users.insert(profile)
  rescue Exception => e
    puts e.inspect
    puts people.inspect
  end
end

def filter li_users, regex = /(C.O|Advisor|Director|Chairman|Marketing|Board Member|President|VP, Sales|Vice President, Sales|Chief (Executive|Operations|Operating|Revenue) Officer|Founder|Managing Partner|SVP|VP Product)/i
  non_execs = {}
  li_users.find({}).each do |p|
    is_ceo = false
    p["relationships"].each do |r|
        #p r["title"]
        is_ceo = true if r["title"] =~ regex
    end if p["relationships"]
    non_execs[p["permalink"]] = p unless is_ceo
  end

  File.open("#{Time.now.strftime('%y%m%d%M%S_results.tsv')}","w+") do |f|
    non_execs.each do |k, ne|
    
      relationships = if ne["relationships"]
        ne["relationships"].map{ |r| r["title"] }.join("\t")
      else
        ""
      end

      next unless ne["web_presences"]
      
      lin = ne["web_presences"].reject { |w| !w["external_url"].include?("linkedin.com/in") }.first["external_url"]
      
      f.write("#{k}\t#{lin}\t" + relationships + "\n")
    end
  end

  puts "We found #{non_execs.size} potential candidates"
end

def fetch_from_linked_in file='1201285931_results.tsv'
  return unless file
  require 'fastercsv'
  require 'mechanize'
  agent = Mechanize.new
  count = 100
  attempts = 0
  FasterCSV.foreach(file, {:col_sep =>"\t"}) do |row|
    attempts = attempts + 1
    puts row.inspect
    lin = row[1]
    page = agent.get lin
    puts page.search('//span[@class="locality"]').inner_text.strip!
    break if attempts == count
  end
  puts "DONE"
end