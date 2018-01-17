require_relative '../app'

ActiveRecord::Base.logger.level = 1
medications_file = ARGV.first

count = 0
CSV.foreach(medications_file, headers: false, encoding: 'ISO-8859-1') do |row|
  rxcui = row[0].to_i
  name = RxcuiLookup.find_by_rxcui(rxcui)
  Medication.find_or_create_by(rxcui: rxcui, name: name)
  count += 1
  puts "#{count} files uploaded. Last file: #{rxcui}" if count % 100 == 1
end

puts Document.count
