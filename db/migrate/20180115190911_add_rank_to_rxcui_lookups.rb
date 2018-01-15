class AddRankToRxcuiLookups < ActiveRecord::Migration[5.1]
  def change
    add_column :rxcui_lookups, :rank, :integer
  end
end
