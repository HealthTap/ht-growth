# Stores static content data in a dynamodb document
# Original data can be replaced (for example RxNorm gets updated, medications
# documents should be replaced)
# All changes are logged and should be able to be replayed (document rebase)
# Option to build change approval here
class Document < ActiveRecord::Base
  validates_presence_of :document_key, :table_name
  validates_uniqueness_of :document_key
  has_many :document_edits

  def contents
    Healthtap::NoSql.item(table_name, document_key: document_key)
  end

  # Dynamo rejects the following values: nil, '', []
  def sanitize_for_dynamo(content)
    if content.is_a?(Array)
      content.delete_if do |e|
        sanitize_for_dynamo(e)
        bad_dynamo_value(e)
      end
    elsif content.is_a?(Hash)
      content.delete_if do |_k, v|
        sanitize_for_dynamo(v)
        bad_dynamo_value(v)
      end
    end
  end

  def bad_dynamo_value(e)
    e.nil? || (e.respond_to?(:empty?) && e.empty?)
  end

  def overwrite(new_content)
    item = {
      document_key: document_key
    }
    sanitize_for_dynamo(new_content)
    item.merge!(new_content)
    Healthtap::NoSql.put_item(table_name, item)
  end

  # Create and try to execute an edit in dynamo db
  def create_and_execute_edit(edit_type, attribute_path, value = nil)
    sanitize_for_dynamo(value)
    edit = DocumentEdit.new(edit_type: edit_type,
                            attribute_path: attribute_path,
                            value: value, document: self)
    message = edit.execute_change
    edit.save
    message
  end

  # Execute all document_edits on the document. Useful if you want to
  # update fields the original document, but also would like to preserve edits
  # people have made.
  def replay_edits
    document_edits.order(:id).each(&:execute_change)
  end

  # Only 4 types of edits we are allowed to make.
  # Dynamo documents take on a json form, ex: { foo: { bar: 1, l: [1,2,3] } }
  # Attribute Path takes on the form: parent.children[index]
  # To access bar, attribute_path = 'foo.bar'
  # To access l[0], attribute_path = 'foo.l[0]'

  # Replaces attribute_path with value
  def update_content(attribute_path, value)
    create_and_execute_edit('SET', attribute_path, value)
  end

  # Removes attribute_path from document
  def remove_content(attribute_path)
    create_and_execute_edit('REMOVE', attribute_path)
  end

  # Add element to attribute_path. Attribute_path must be array
  def add_to_array(attribute_path, value)
    create_and_execute_edit('ADD', attribute_path, value)
  end

  # Remove element to attribute_path. Attribute_path must be array
  def delete_from_array(attribute_path, value)
    create_and_execute_edit('DELETE', attribute_path, value)
  end

end
