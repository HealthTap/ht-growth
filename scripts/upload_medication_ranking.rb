require_relative '../app'

# ActiveRecord::Base.logger.level = 1
traffic_file = ARGV.first

traffic_pairs = []
CSV.foreach(traffic_file, headers: false, encoding: 'ISO-8859-1') do |row|
  name = row[0]
  traffic = row[2].to_i
  traffic_pairs.push([name, traffic]) if traffic
end

count = 0
RxcuiLookup.update_all(rank: nil)
traffic_pairs.sort{ |a, b| b[1] <=> a[1] }.each_with_index do |pair, i|
  rx = RxcuiLookup.find_by_name(pair[0])
  rx.update_attribute(:rank, i)
  count += 1
  puts "#{count} medications update. Last: #{rx&.name}" if count % 1000 == 1
end
