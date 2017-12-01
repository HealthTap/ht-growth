class CreateMedicationInteractions < ActiveRecord::Migration[5.1]
  def change
    create_table :medication_interactions do |t|
      t.integer :interacts_with_rxcui
      t.integer :ingredient_rxcui
      t.integer :rank
      t.string :severity
      t.text :description
      t.belongs_to :medication, index: true
    end
  end
end
