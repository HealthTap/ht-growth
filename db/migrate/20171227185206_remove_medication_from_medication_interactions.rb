class RemoveMedicationFromMedicationInteractions < ActiveRecord::Migration[5.1]
  def change
    remove_reference :medication_interactions,
                     :medication
  end
end
