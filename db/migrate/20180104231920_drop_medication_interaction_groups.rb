class DropMedicationInteractionGroups < ActiveRecord::Migration[5.1]
  def change
    drop_table :medication_interaction_groups
  end
end
