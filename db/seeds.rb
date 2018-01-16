# TODO: Organize better

require 'csv'
require 'activerecord-import'

# Seed files
seeds_directory = "#{App.settings.root}/lib/seeds"

# Create description lookups
puts 'Seeding descriptions'
descriptions_file = "#{seeds_directory}/descriptions.csv"
descriptions = []
CSV.foreach(descriptions_file, headers: true, encoding: 'ISO-8859-1') do |row|
  descriptions << Description.new(category: row['category'],
                                  name: row['name'],
                                  value: row['value'])
end
Description.import descriptions

# Create Rxcui lookups
if RxcuiLookup.count < 100_000
  puts 'Seeding rxcui lookup'
  rxcui_traffic_filename = "#{seeds_directory}/rxcui_traffic.csv"
  rxcui_rank = {}
  i = 0
  CSV.foreach(rxcui_traffic_filename, headers: true, encoding: 'ISO-8859-1') do |row|
    rxcui_rank[row['rxcui'].to_i] = i
    i += 1
  end
  rxcui_filename = "#{seeds_directory}/rxcui_lookups.csv"
  lookups = []
  CSV.foreach(rxcui_filename, headers: true, encoding: 'ISO-8859-1') do |row|
    lookups << RxcuiLookup.new(rxcui: row['rxcui'].to_i, name: row['name'], rank: rxcui_rank[row['rxcui'].to_i])
  end
  RxcuiLookup.import lookups
end
