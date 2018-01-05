# TODO: Organize better

require 'csv'
require 'activerecord-import'

# Seed files
seeds_directory = "#{App.settings.root}/lib/seeds"

# Create Tribenzor
Medication.create(name: 'Acetaminophen', rxcui: 1_000_001)

# Populate Tribenzor with some content
puts 'Seeding Acetaminophen data'
acetaminophen_filename = "#{seeds_directory}/sample_medication.json"
acetaminophen = Medication.find_by_name('Acetaminophen')
acetaminophen.upload_data(Oj.load(File.read(acetaminophen_filename)))

# Create description lookups
puts 'Seeding descriptions'
descriptions_file = "#{seeds_directory}/descriptions.csv"
descriptions = []
CSV.foreach(descriptions_file, headers: true, encoding: 'ISO-8859-1') do |row|
  descriptions << Description.new(category: row['category'],
                                  name: row['name'],
                                  value: row['value'])
end
begin
  Description.import descriptions
rescue
  puts 'Descriptions seed failed'
end

# Create Rxcui lookups
puts 'Seeding rxcui lookup'
rxcui_filename = "#{seeds_directory}/rxcui_lookups.csv"
lookups = []
CSV.foreach(rxcui_filename, headers: true, encoding: 'ISO-8859-1') do |row|
  lookups << RxcuiLookup.new(rxcui: row['rxcui'].to_i, name: row['name'])
end
begin
  RxcuiLookup.import lookups
rescue
  puts 'Rxcui lookups seed failed'
end

# Create some sample interactions
puts 'Seeding sample interactions'
interactions_file = "#{seeds_directory}/interactions_sample.json"
interactions_json = Oj.load File.read(interactions_file)
interactions_json.each do |rxcui, interactions_data|
  Medication.find_by_rxcui(rxcui.to_i)&.create_interactions(interactions_data)
end
