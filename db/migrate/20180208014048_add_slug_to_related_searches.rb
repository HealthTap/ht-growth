class AddSlugToRelatedSearches < ActiveRecord::Migration[5.1]
  def change
    add_column :related_searches, :slug, :string
    add_index :related_searches, :slug, unique: true
  end
end
