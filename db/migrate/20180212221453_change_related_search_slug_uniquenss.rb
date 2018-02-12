class ChangeRelatedSearchSlugUniquenss < ActiveRecord::Migration[5.1]
  def change
    remove_index :related_searches, :slug
    add_index :related_searches, :slug
  end
end
