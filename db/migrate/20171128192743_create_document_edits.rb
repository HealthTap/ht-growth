class CreateDocumentEdits < ActiveRecord::Migration[5.1]
  def change
    create_table :document_edits do |t|
      t.string :edit_type
      t.string :attribute_path
      t.string :value
      t.belongs_to :document, index: true
    end
  end
end
