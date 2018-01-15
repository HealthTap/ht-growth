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

# Create Medications
if Medication.count < 10_000
  puts 'Seeding medications'
  medications_filename = "#{seeds_directory}/brand_names_and_ingredients.csv"
  names = []
  medications = []
  CSV.foreach(medications_filename, headers: true, encoding: 'ISO-8859-1') do |row|
    names << row['name']
  end
  RxcuiLookup.where(name: names).select(:name, :rxcui).each do |lookup|
    medications << Medication.new(name: lookup.name, rxcui: lookup.rxcui)
  end
  Medication.import medications

  # Create Document
  puts 'Filling documents'
  documents = []
  Medication.pluck(:rxcui).each do |rxcui|
    documents << Document.new(document_key: rxcui, table_name: 'medications')
  end
  Document.import documents
end


# Populate Acetaminophen with some content
acetaminophen_filename = "#{seeds_directory}/acetaminophen.json"
acetaminophen = Medication.find_by_name('Acetaminophen')
acetaminophen.upload_data(Oj.load(File.read(acetaminophen_filename)))
ibuprofen_filename = "#{seeds_directory}/ibuprofen.json"
ibuprofen = Medication.find_by_name('Ibuprofen')
ibuprofen.upload_data(Oj.load(File.read(ibuprofen_filename)))

# Create some sample interactions
puts 'Seeding sample interactions'
interactions_file = "#{seeds_directory}/interactions_sample.json"
interactions_json = Oj.load File.read(interactions_file)
interactions_json.each do |rxcui, interactions_data|
  Medication.find_by_rxcui(rxcui.to_i)&.create_interactions(interactions_data)
end
