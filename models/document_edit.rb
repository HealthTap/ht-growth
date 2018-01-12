# A single atomic change to a Dynamo document
# Only supports set and delete attribute
class DocumentEdit < ActiveRecord::Base
  validates_presence_of :edit_type, :attribute_path
  serialize :value
  belongs_to :document

  def item_hash
    { document_key: document.document_key }
  end

  # Execute atomic change. Should return 0 if successful
  def execute_change
    alias_mapping, alias_str =
      Healthtap::NoSql.attribute_alias(attribute_path)
    params = {
      update_expression:
      edit_type == 'REMOVE' ? "REMOVE #{alias_str}" : "SET #{alias_str} = :v",
      expression_attribute_names: alias_mapping
    }
    unless edit_type == 'REMOVE'
      params[:expression_attribute_values] = { ':v': replacement_value }
    end
    update_item(params) # TODO verify that item was updated
  end


  # Replacement value as dynamodb doesn't allow add/delete for nested attributes
  def replacement_value
    case edit_type
    when 'SET'
      value
    when 'ADD'
      a = Healthtap::NoSql.attribute_value(document.table_name,
                                           item_hash, attribute_path) || []
      a.append(value)
    when 'DELETE'
      a = Healthtap::NoSql.attribute_value(document.table_name,
                                           item_hash, attribute_path) || []
      a - [value]
    end
  end

  # Replace attribute in dynamo document with new value
  def update_item(params)
    Healthtap::NoSql.update_item(document.table_name,
                                 item_hash,
                                 params)
  end
end
