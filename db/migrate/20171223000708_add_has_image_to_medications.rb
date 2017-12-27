class AddHasImageToMedications < ActiveRecord::Migration[5.1]
  def change
    add_column :medications, :has_image, :boolean
  end
end
