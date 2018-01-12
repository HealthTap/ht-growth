class CreateHtmlSitemaps < ActiveRecord::Migration[5.1]
  def change
    create_table :html_sitemaps do |t|
      t.string :name
      t.string :model
      t.belongs_to :concept_tree, index: true
    end
  end
end
