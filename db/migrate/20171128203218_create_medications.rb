class CreateMedications < ActiveRecord::Migration[5.1]
  def change
    create_table :medications do |t|
      t.string :name
      t.string :seo_flag
      t.string :experiment_group
      t.belongs_to :document, index: true
    end
  end
end
