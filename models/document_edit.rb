# A single atomic change to a Dynamo document
# Only supports set and delete attribute
class DocumentEdit < ActiveRecord::Base
  validates_presence_of :edit_type, :attribute_path
  serialize :value
  belongs_to :document

  # Execute atomic change. Should return 0 if successful
  def execute_change
    alias_mapping, alias_str = attribute_alias
    params = {
      update_expression:
      edit_type == 'REMOVE' ? "REMOVE #{alias_str}" : "SET #{alias_str} = :v",
      expression_attribute_names: alias_mapping
    }
    unless edit_type == 'REMOVE'
      params[:expression_attribute_values] = { ':v': replacement_value }
    end
    update_item(params) # TODO verify that item was updated
    return 0
  rescue
    'Change failed'
  end

  # Returns alias name mapping and combined expression for dynamodb request
  def attribute_alias
    alias_mapping = {}
    alias_str = ''
    attribute_path.split('.').each do |attribute|
      index = ''
      if attribute.include?('[')
        attr_split = attribute.split('[')
        attribute = attr_split[0]
        index = '[' + attr_split[1]
      end
      alias_mapping["##{attribute}"] = attribute
      alias_str += "##{attribute}#{index}."
    end
    [alias_mapping, alias_str[0..-2]]
  end

  # Replacement value as dynamodb does not allow add/delete for nested
  # attributes
  def replacement_value
    case edit_type
    when 'SET'
      value
    when 'ADD'
      a = attribute_value
      a.append(value)
    when 'DELETE'
      a = attribute_value
      a - [value]
    end
  end

  def attribute_value
    alias_mapping, projection_expression = attribute_alias
    params = {
      expression_attribute_names: alias_mapping,
      projection_expression: projection_expression
    }
    Healthtap::NoSql.get_item(document.table_name, { name: document.name },
                              params).values[0] || []
  end

  def update_item(params)
    Healthtap::NoSql.update_item(document.table_name, { name: document.name },
                                 params)
  end
end
