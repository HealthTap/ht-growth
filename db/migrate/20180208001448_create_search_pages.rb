class CreateSearchPages < ActiveRecord::Migration[5.1]
  def change
    create_table :search_pages do |t|
      t.string :name
      t.string :seo_flag
      t.datetime :updated_at
      t.string :slug
      t.index :slug, unique: true
    end
  end
end
