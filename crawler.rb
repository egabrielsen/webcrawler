require "mechanize"

# used to determine if link is restricted by robots.txt
def is_restricted?(link)
  restricted = false
  @dont_go.each do |dg|
    if link.to_s.include?('dontgohere')
      restricted = true
    end
  end
  restricted
end

# used to find the frequencies of each word in index
def frequencies(words)
  Hash[
    words.group_by(&:downcase).map{ |word,instances|
      [word,instances.length]
    }.sort_by(&:last).reverse
  ]
end

url = "http://lyle.smu.edu/~fmoore/"
robots = "http://lyle.smu.edu/~fmoore/robots.txt"

## reveiving command line arguments
# number of pages read in argument
if ARGV[0]
  num_pages = ARGV[0].to_i
else
  num_pages = 100
end

#recieves list of stop words from command line
stop_words = []
ARGV.each_with_index do |arg, i|
  unless i == 0
    stop_words << arg
  end
end

#variables used for File IO
@pages_file = File.new("pages.txt", "w")
@pages_file.write("Pages \n\n")
@frequency_index = File.new("freq.txt", "w")
@frequency_index.write("Word Frequency \n\n")
@doc_id_index = File.new("doc_id.txt", "w")
@doc_id_index.write("Word Document Id Index \n\n")
@broken_links = File.new("broken_links.txt", "w")
@broken_links.write("Broken Links \n\n")
@fp = File.new("links.txt", "w")
@fp.write("Links \n\n")
@visited = []

@agent = Mechanize.new { |agent| agent.user_agent_alias = "Mac Safari"}

## Get robots.txt
html = @agent.get(url).body
body = ''
@agent.get(robots) do |page|
  body = page.body
end

## Put robots.txt info inside of array for places to not go
## used in is_restricted? method
@dont_go = []
body.each_line do |line|
  unless /^#/.match(line)
    unless /^User-agent/.match(line)
      token = line.split(": ")
      @dont_go << token[1].tr('/','').to_s
    end
  end
end

## Scraping Begins
html_doc = Nokogiri::HTML(html)

@pages_file.write(url + "\n")

link_list = []

#block that gets first first page of the site and collects all links on page
@agent.get("http://lyle.smu.edu/~fmoore/") do |page|
  page.links_with(:href => //).each do |link|
    if link.href.to_s.include?(':') #determine if link is full link
      link_list << link.href.to_s
    else              # if not full link, make full link to avoid 404 errors
      link_list << "http://lyle.smu.edu/~fmoore/#{link.href.to_s}"
    end
  end
end

all_text = ''
all_tokens = {}

id = 0 #used for document id
num = 1 #used to determine how many pages to scrape
num_jpegs = 0 #keeps track of number of jpegs in site

# main driver of scraper
link_list.each do |link|
  #if reached end of max number of pages, stop scraping.
  if num >= num_pages
    break
  end

  unless !link.include?('lyle.smu.edu/~fmoore/') || is_restricted?(link) || @visited.include?(link)
    # 404 error handling with links
    begin
      page = @agent.get(link)
    rescue Exception => e
      page = e.page
    end

    # => increment id and num for each iteration
    id = id + 1
    num = num + 1
    @visited << link # => add link to visited list
    @pages_file.write(link.to_s + "\n") # => write visited link to file

    html_doc = Nokogiri::HTML(page.body)
    text = html_doc.at('body').inner_text

    all_text << text # => adds text from body to all text for token frequency determination

    # Pretend that all words we care about contain only a-z, 0-9, or underscores
    text.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    tokens = text.scan(/[a-z]+/i)

    # => collects all unique occurences of words and creates doc_id data structure
    tokens.each do |token|
      token.downcase!
      if all_tokens.key?(token) && !stop_words.include?(token)
        unless all_tokens[token].include?(id)
          all_tokens[token] << id
        end
      elsif !stop_words.include?(token)
        all_tokens[token] = []
        all_tokens[token] << id
      end
    end

    # => handles jpeg number
    jpegs = html_doc.xpath("//img")
    jpegs.each do |jpeg|
      num_jpegs = num_jpegs + 1
    end

    # => gathers all links on page and adds to list.
    links = html_doc.xpath("//a/@href")
    links.each do |link2|
      if link2.to_s.include?('http://')
        link_list << link2
      else
        link_list << "http://lyle.smu.edu/~fmoore/#{link2}"
      end
      if link2.to_s.include?('jpg')
        num_jpegs = num_jpegs + 1
      end
    end
  end
end

puts "Number of JPEGS => #{num_jpegs}"

# creates document Id index file
all_tokens.each do |tok|
  @doc_id_index.write("#{tok[0]} => #{tok[1]}\n")
end

# creates word frequency index file
all_text.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
words = all_text.scan(/[a-z]+/i)
frequencies(words).each do |word|
  unless stop_words.include?(word[0])
    @frequency_index.write("#{word[0]} => #{word[1]} \n")
  end
end

# lists all links
link_list.each do |link|
  @fp.write(link.to_s + "\n")
end

# lists all broken links
link_list.each do |link|
  unless link.include?('mailto:') || is_restricted?(link)
    begin
      page = @agent.get(link)
    rescue Exception => e
      @broken_links.write("#{link} \n")
      page = e.page
    end
  end
end
