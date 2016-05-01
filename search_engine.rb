require "mechanize"
require 'json'
require 'matrix'
require 'tf-idf-similarity'

search = true
NUM_TIMES = 3 #number of results to display

puts "       .--.--.                                            ,---,                ,---,.                                                        \n"
puts "      /  /    '.                                        ,--.' |              ,'  .' |                         ,--,                           \n"
puts "     |  :  /`. /                         __  ,-.        |  |  :            ,---.'   |      ,---,            ,--.'|         ,---,             \n"
puts "     ;  |  |--`                        ,' ,'/ /|        :  :  :            |   |   .'  ,-+-. /  |  ,----._,.|  |,      ,-+-. /  |            \n"
puts "     |  :  ;_       ,---.     ,--.--.  '  | |' | ,---.  :  |  |,--.        :   :  |-, ,--.'|'   | /   /  ' /`--'_     ,--.'|'   |   ,---.    \n"
puts "      \\  \\    `.   /     \\   /       \\ |  |   ,'/     \\ |  :  '   |        :   |  ;/||   |  ,\"' ||   :     |,' ,'|   |   |  ,\"' |  /     \\   \n"
puts "       `----.   \\ /    /  | .--.  .-. |'  :  / /    / ' |  |   /' :        |   :   .'|   | /  | ||   | .\\  .'  | |   |   | /  | | /    /  |  \n"
puts "       __ \\  \\  |.    ' / |  \\__\\/: . .|  | ' .    ' /  '  :  | | |        |   |  |-,|   | |  | |.   ; ';  ||  | :   |   | |  | |.    ' / |  \n"
puts "      /  /`--'  /'   ;   /|  ,\" .--.; |;  : | '   ; :__ |  |  ' | :        '   :  ;/||   | |  |/ '   .   . |'  : |__ |   | |  |/ '   ;   /|  \n"
puts "     '--'.     / '   |  / | /  /  ,.  ||  , ; '   | '.'||  :  :_:,'        |   |    ||   | |--'   `---`-'| ||  | '.'||   | |--'  '   |  / |  \n"
puts "       `--'---'  |   :    |;  :   .'   \\---'  |   :    :|  | ,'            |   :   .'|   |/       .'__/\\_: |;  :    ;|   |/      |   :    |  \n"
puts "                  \\   \\  / |  ,     .-./       \\   \\  / `--''              |   | ,'  '---'        |   :    :|  ,   / '---'        \\   \\  /   \n"
puts "                   `----'   `--`---'            `----'                     `----'                  \\   \\  /  ---`-'                `----'    \n"
puts "                                                                                                    `--`-'                                  \n\n"


## Load data structure for searching
# file = File.read('doc_id.txt')
# data = JSON.parse(file)
all_data = []
ids = []
line_num = 0
File.open("tokens.txt", "r") do |f|
  f.each_line do |line|
    if line_num % 2 == 0
      ids << line
    else
      # word = line.strip
      all_data << TfIdfSimilarity::Document.new(line)
    end
    line_num = line_num + 1
  end
end
model = TfIdfSimilarity::TfIdfModel.new(all_data)
matrix = model.similarity_matrix

deleters = []

#marking duplicate documents based on similar cosine similarity values
all_data.each_with_index do |data, i|
  all_data.each_with_index do |data2, j|
    ## Get cosine similarity value
    value = matrix[model.document_index(data), model.document_index(data2)]
    ## Matches if cosine similarity of 1
    if value >= 0.99 && j > i
      ## Marks duplicares
      all_data[j] = "PLEASE DELETE ME ------"
      ids[j] = "PLEASE DELETE ME ------"
    end
  end
end

## Deleting duplicates
all_data.delete_if {|x| x == "PLEASE DELETE ME ------"}
ids.delete_if {|x| x == "PLEASE DELETE ME ------"}

last_index = 0
ids.each do |id|
  last_index += 1
end

while search
  results = []

  puts "Type 'Quit' to quit"
  print "Search: "
  query = gets.chomp

  if query == "Quit"
    puts "Thank you for searching!"
    search = false
  else
    ## Do results here
    puts "\tQuery: #{query}\n"
    all_data << TfIdfSimilarity::Document.new(query)
    new_model = TfIdfSimilarity::TfIdfModel.new(all_data)
    new_matrix = new_model.similarity_matrix
    all_data.each_with_index do |data, i|
      unless i == last_index
        value = new_matrix[new_model.document_index(data), new_model.document_index(all_data[last_index])]
        results << {url: "#{ids[i].strip}", value: value}
      end
    end
    all_data.delete_at(last_index)
    results = results.sort_by { |k| k[:value] }.reverse
    puts "------ RESULTS -------\n\n"
    NUM_TIMES.times do |i|
      puts "\t#{i + 1}. #{results[i][:url]}"
      puts "\t\tCosine similarity value: #{results[i][:value]}"
    end
    puts "\n"
  end
end
