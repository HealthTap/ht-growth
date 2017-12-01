# TODO: Organize better

require 'csv'
require 'activerecord-import'

# Seed files
seeds_directory = "#{App.settings.root}/lib/seeds"

# Create Tribenzor
Medication.create(name: 'tribenzor', rxcui: 1000001)

# Populate Tribenzor with some content
puts 'Uploading Tribenzor data'
tribenzor_filename = "#{seeds_directory}/sample_document_tribenzor.json"
tribenzor = Medication.find_by_name('tribenzor')
tribenzor.document.overwrite(Oj.load(File.read(tribenzor_filename)))

# Creating Rxcui lookups
puts 'Uploading rxcui lookup'
rxcui_filename = "#{seeds_directory}/rxcui_lookups.csv"
lookups = []
CSV.foreach(rxcui_filename, headers: true, encoding: 'ISO-8859-1') do |row|
  lookups << RxcuiLookup.new(rxcui: row['rxcui'].to_i, name: row['name'])
end
begin
  RxcuiLookup.import lookups
rescue
  puts 'Rxcui lookup upload failed'
end

# Creating some sample interactions
puts 'Uploading sample interactions'
interactions_file = "#{seeds_directory}/interactions_sample.json"
interactions_json = Oj.load File.read(interactions_file)
interactions_json.each do |rxcui, interactions_data|
  Medication.find_by_rxcui(rxcui.to_i)&.create_interactions(interactions_data)
end
