url_map_file = ARGV[0]
image_directory = ARGV[1]

id_lookup = {}
CSV.foreach(url_map_file, headers: true, encoding: 'ISO-8859-1') do |row|
  id_lookup[row['rxcui'].to_i] = row['id']
end

rxcui_lookups = {}
RxcuiLookup.where(rxcui: id_lookup.keys).each do |lookup|
  rxcui_lookups[lookup.rxcui] = lookup.name
end

id_lookup.each do |rxcui, id|
  s = rxcui_lookups[rxcui]
  next unless s
  image_file = "#{image_directory}/#{rxcui}_#{id}.png"
  unless s.include?(' / ')
    drug_name = /(([a-zA-Z]|\s+).*?) (([0-9]|\.){1,} [a-zA-Z]{1,3})/.match(s)[1]&.strip
    drug_name = drug_name.slice(3..-1) if drug_name.starts_with?('Hr ')
    Medication.find_by_name(drug_name)&.upload_image(image_file)
  end
  drug_name = /\[(.*?)\]/.match(s)&.to_a&.slice(1)&.strip
  next unless drug_name
  Medication.find_by_name(drug_name)&.upload_image(image_file)
  Medication.find_by_name(drug_name.split(' ')[0])&.upload_image(image_file)
end

puts Medication.where(has_image: true).count
