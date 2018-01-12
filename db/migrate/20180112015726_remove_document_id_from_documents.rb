class RemoveDocumentIdFromDocuments < ActiveRecord::Migration[5.1]
  def change
    remove_column :medications, :document_id
  end
end
