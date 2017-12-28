class AddUpdatedAtToMedications < ActiveRecord::Migration[5.1]
  def change
    add_column :medications, :updated_at, :datetime
  end
end
