class CreateRelatedSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :related_searches do |t|
      t.string :search_string
      t.string :flag
      t.integer :rank
      t.references :has_searches,
                   polymorphic: true,
                   index: {
                     name: 'index_rs_on_hs_type_and_hs_id' # Abbreviate name
                   }
    end
  end
end
