# Stores static content data in a dynamodb document
# Original data can be replaced (for example RxNorm gets updated, medications
# documents should be replaced)
# All changes are logged and should be able to be replayed (document rebase)
# Option to build change approval here
class Document < ActiveRecord::Base
  validates_presence_of :name, :table_name
  validates_uniqueness_of :name
  has_many :document_edits

  def contents
    Healthtap::NoSql.get_item(table_name, name: name)
  end

  def sanitize_for_nosql(content)

  end

  def overwrite(new_content)
    item = {
      name: name
    }
    item.merge!(new_content)
    Healthtap::NoSql.put_item(table_name, item)
  end

  def create_and_execute_edit(edit_type, attribute_path, value = nil)
    edit = DocumentEdit.new(edit_type: edit_type,
                            attribute_path: attribute_path,
                            value: value, document: self)
    message = edit.execute_change
    edit.save unless message != 0
    message
  end

  def update_content(attribute_path, value)
    create_and_execute_edit('SET', attribute_path, value)
  end

  def remove_content(attribute_path)
    create_and_execute_edit('REMOVE', attribute_path)
  end

  def add_to_array(attribute_path, value)
    create_and_execute_edit('ADD', attribute_path, value)
  end

  def delete_from_array(attribute_path, value)
    create_and_execute_edit('DELETE', attribute_path, value)
  end

  def replay_edits
    document_edits.order(:id).each(&:execute_change)
  end
end
