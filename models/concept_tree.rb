# Stores large trees in DynamoDB
# Trees should be generated offline and uploaded
# Should not be able to update this, only allowed to overwrite
# Examples: drugs organized by classes for a sitemap, doctor directories, etc.
# Stores large trees in multiple dynamodb items
class ConceptTree < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  serialize :item_mapping, Hash

  after_initialize :default_mapping

  TABLE_NAME = 'concept-trees'.freeze

  def default_mapping
    self.item_mapping ||= {}
  end

  def tree
    ret = {}
    (0..num_items - 1).each do |i|
      ret.merge!(Healthtap::NoSql.item(TABLE_NAME, Name: "#{name}-#{i}"))
    end
    ret.delete('Name')
    ret
  end

  def clear_items(range)
    range.each do |i|
      item = { Name: "#{name}-#{i}" }
      Healthtap::NoSql.delete_item(TABLE_NAME, item)
    end
  end

  def overwrite_tree(tree)
    # Amateur way of making sure items are below 400kb
    num_groups = Oj.dump(tree).length / 50_000 + 1
    sliced_hash = tree.to_a.in_groups_of(tree.keys.count / num_groups, false)
    new_mapping = {}
    sliced_hash.each_with_index do |part, i|
      part = part.to_h
      new_mapping.merge!(part.keys.map{ |k| [k, i] }.to_h)
      item = part.merge(Name: "#{name}-#{i}")
      Healthtap::NoSql.put_item(TABLE_NAME, item)
    end
    old_num_items = num_items
    update_attribute(:item_mapping, new_mapping)
    update_attribute(:num_items, sliced_hash.count)
    clear_items(num_items..old_num_items - 1) if old_num_items > num_items
  end

  def path(path_arr = [])
    return item_mapping if path_arr.empty?
    expression = path_arr.join('.')
    i = item_mapping[path_arr.first]
    Healthtap::NoSql.attribute_value(TABLE_NAME,
                                     { Name: "#{name}-#{i}" },
                                     expression)
  end
end
