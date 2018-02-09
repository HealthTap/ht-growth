class AddDefinitionToSearchPages < ActiveRecord::Migration[5.1]
  def change
    add_column :search_pages, :topic, :string
    add_column :search_pages, :definition, :text
  end
end
