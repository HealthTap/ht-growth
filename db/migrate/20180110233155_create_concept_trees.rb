class CreateConceptTrees < ActiveRecord::Migration[5.1]
  def change
    create_table :concept_trees do |t|
      t.string :name
      t.integer :num_items
      t.text :item_mapping
    end
  end
end
