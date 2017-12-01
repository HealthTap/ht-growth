class CreateRxcuiLookups < ActiveRecord::Migration[5.1]
  def change
    create_table :rxcui_lookups, primary_key: :rxcui do |t|
      t.text :name
    end
  end
end
