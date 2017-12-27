class ChangeMedicationInteractions < ActiveRecord::Migration[5.1]
  def change
    add_column :medication_interactions, :ingredient_name, :text
    add_column :medication_interactions, :ingredient_url, :string
    add_column :medication_interactions, :interacts_with_name, :text
    add_column :medication_interactions, :interacts_with_url, :string
    add_reference :medication_interactions,
                  :medication_interaction_group, index: true
  end
end
