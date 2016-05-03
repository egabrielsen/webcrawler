require "mechanize"
require 'json'
require 'matrix'
require 'tf-idf-similarity'

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

#variables used for File IO
@pages_file = File.new("pages.txt", "w")
@pages_file.write("\n")
@frequency_index = File.new("freq.txt", "w")
@frequency_index.write("Word Frequency \n\n")
@fp = File.new("links.txt", "w")
@fp.write("Links \n\n")
@tokens = File.new("tokens.txt", "w")
@visited = []
stop_words = []

# Retreives list of stop words and stores it in array
File.open("stop_words.txt", "r") do |f|
  f.each_line do |line|
    word = line.strip
    stop_words << word
  end
end

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

id = '' #used for document id
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
    id = link
    num = num + 1
    @visited << link # => add link to visited list
    @pages_file.write(link.to_s + "\n") # => write visited link to file

    html_doc = Nokogiri::HTML(page.body)
    text = html_doc.at('body').inner_text

    all_text << text # => adds text from body to all text for token frequency determination

    # Pretend that all words we care about contain only a-z, 0-9, or underscores
    text.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    tokens = text.scan(/[a-z]+/i)  #only take in words with a - z

    new_tokens = []

    ## Get rid of stop words
    tokens.each do |token|
      token.downcase!
      unless stop_words.include?(token)
        new_tokens << token
      end
    end
    @tokens.write("#{link}\n")
    new_tokens.each do |token|
      @tokens.write("#{token} ")
    end
    @tokens.write("\n")
    # => collects all unique occurences of words and creates doc_id data structure
    # tokens.each do |token|
    #   token.downcase!
    #   if all_tokens.key?(token) && !stop_words.include?(token)
    #     if all_tokens[token].key?("#{id}")
    #       all_tokens[token]["#{id}"] = all_tokens[token]["#{id}"] + 1
    #     else
    #       all_tokens[token]["#{id}"] = 1
    #     end
    #   elsif !stop_words.include?(token)
    #     all_tokens[token] = {}
    #     all_tokens[token]["#{id}"] = 1
    #   end
    # end

    # => gathers all links on page and adds to list.
    links = html_doc.xpath("//a/@href")
    new_link = link.to_s
    new_link.sub!(link.split('/').last.to_s, "")
    links.each do |link2|
      if link2.to_s.include?('http')
        link_list << link2
      elsif link2.to_s.include?('mailto:')
        #do nothing with link
      else
        link_list << "#{new_link}#{link2}"
      end
    end
  end
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
