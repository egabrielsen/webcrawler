# Erik's Web Crawler
A ruby based web crawler that pull information from lyle.smu.edu/~fmoore/ and creates an inverted index, a word frequency list, a list of pages, and all links.

##Software
Software Used:
<ul>
<li>Ruby version 1.9.3</li>
<li>Mechanize Gem </li>
<li>Nokogiri Gem</li>
</ul>

##Installation
This web crawler uses ruby version 1.9.3. I use RVM to control which verion of ruby to use during a program. There are other ways to install ruby, however the steps below assume rvm is installed<br><br>
To install the correct ruby version run <code>rvm install ruby-1.9.3</code><br>
Next install the mechanize gem, which directs you to the correct web page, and Nokogiri, the html parser used as the web crawler<br>
<code>gem install mechanize</code><br>
<code>gem install nokogiri</code>

##Use
To use the web crawler, run from terminal:
<code>ruby crawler.rb [num of pages] [stop word list]</code>
<br>
This will produce several .txt files:<br>
<ul>
<li>pages.txt -> the pages visited by the web crawler </li>
<li>links.txt -> all links discovered by the crawler </li>
<li>broken_links.txt -> all broken links in site</li>
<li>doc_id.txt -> a list of words with their respective document Ids</li>
<li>freq.txt -> list of terms and their frequency</li>
</ul>
