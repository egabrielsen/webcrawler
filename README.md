# Erik's Web Crawler and Search Engine
A ruby based web crawler and search engine that pull information from lyle.smu.edu/~fmoore/ and creates an inverted index, a word frequency list, a list of pages, and all links. The Search Engine loads the text from recorded pages provided by tokens.txt and loads them into tf-idf-similarity Objects that are able to form cosine similarity matrices with other objects in order to remove duplicate pages, and return the correct results to the user.

##Software
Software Used:
<ul>
<li>Ruby version 1.9.3</li>
<li>Mechanize Gem </li>
<li>Nokogiri Gem</li>
<li>tf-idf-similarity Gem</li>
</ul>

##Installation
This web crawler uses ruby version 1.9.3. I use RVM to control which verion of ruby to use during a program. There are other ways to install ruby, however the steps below assume rvm is installed<br><br>
To install the correct ruby version run <code>rvm install ruby-1.9.3</code><br>
Next install the mechanize gem, which directs you to the correct web page, and Nokogiri, the html parser used as the web crawler<br>
<code>gem install mechanize</code><br>
<code>gem install tf-idf-similarity</code><br>
<code>gem install nokogiri</code>

##Use
To use the web crawler, run from terminal:
<code>ruby crawler.rb</code>
<br>
Stop words are included in a file called stop_words.txt. Running the web crawler will produce several .txt files:<br>
<ul>
<li>pages.txt -> the pages visited by the web crawler </li>
<li>links.txt -> all links discovered by the crawler </li>
<li>broken_links.txt -> all broken links in site</li>
<li>tokens.txt -> a list of urls with their respective document text, This is then loaded in the search engine to create the tf-idf matrix</li>
<li>freq.txt -> list of terms and their frequency</li>
</ul><br>
After these pages are created you may then run the search engine from the terminal by running:
<code>ruby search_engine.rb</code><br>
This will open up an interactive search engine that prompts the user to type a query and displays the top N results. The default is 3 but can be changed by changing the NUM_TIMES variable to equal a different number in 'search_engine.rb'. To quit the search engine simply type the word "Quit"
