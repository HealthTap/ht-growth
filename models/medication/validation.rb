# Json validation before saving
class Medication < ActiveRecord::Base
  def self.validate_json(data)
    schema_file = File.join(File.dirname(__FILE__), './input_data_schema.json')
    schema_data = Oj.load File.read(schema_file)
    schema = JsonSchema.parse!(schema_data)
    schema.expand_references!
    schema.validate!(data)
  end
end
