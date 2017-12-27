class CreateMedicationInteractionGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :medication_interaction_groups do |t|
      t.string :source
      t.text :comment
      t.belongs_to :medication, index: true
    end
  end
end
