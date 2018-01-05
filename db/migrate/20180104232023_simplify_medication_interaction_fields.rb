class SimplifyMedicationInteractionFields < ActiveRecord::Migration[5.1]
  def change
    remove_column :medication_interactions, :ingredient_name
    remove_column :medication_interactions, :ingredient_url
    remove_column :medication_interactions, :interacts_with_name
    remove_column :medication_interactions, :interacts_with_url
    remove_reference :medication_interactions, :medication_interaction_group
    add_reference :medication_interactions, :medication, index: true
  end
end
