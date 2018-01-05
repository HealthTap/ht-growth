class CreateDescriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :descriptions do |t|
      t.string :name
      t.string :category
      t.text :value
    end
  end
end
