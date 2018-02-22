class AddDisplayNameToHtmlSitemaps < ActiveRecord::Migration[5.1]
  def change
    add_column :html_sitemaps, :display_name, :string
  end
end
