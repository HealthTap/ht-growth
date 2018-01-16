require_relative '../app'

ActiveRecord::Base.logger.level = 1
data_folder = ARGV.first
count = 0
Dir.foreach(data_folder) do |f|
  begin
    next unless f.ends_with?('.json')
    medication_data = Oj.load File.read("#{data_folder}/#{f}")
    next unless %w[ingredients brand_name].include?(medication_data['concept_type'])
    rxcui = medication_data['rxcui'].to_i
    next unless (rxcui > 204_319 && rxcui.to_s.starts_with?('2')) || (!rxcui.to_s.starts_with?('1') && !rxcui.to_s.starts_with?('2'))
    name = medication_data['name']
    m = Medication.find_or_create_by(rxcui: rxcui, name: name)
    m.upload_data(medication_data)
    count += 1
    puts "#{count} files uploaded. Last file: #{rxcui}" if count % 100 == 1
  rescue
    puts "Couldn't process #{rxcui}"
  end
end
