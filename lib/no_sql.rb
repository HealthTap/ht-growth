module Healthtap
  # Supports adding, reading, and updating items from DynamoDB
  class NoSql
    @db = nil
    @table_prefix = nil

    def self.connection
      if @db.nil?
        consul_settings = App.settings.consul_settings
        access_key_id = consul_settings[:aws][:access_key_id]
        secret_access_key = consul_settings[:aws][:secret_access_key]
        @db = ::Aws::DynamoDB::Client.new(region: 'us-west-1',
                                          access_key_id: access_key_id,
                                          secret_access_key: secret_access_key)
      end
      @db
    end

    def self.prefix_table(table_name)
      App.settings.nosql['table_prefix'] + table_name
    end

    def self.put_item(table_name, item)
      connection.put_item(table_name: prefix_table(table_name), item: item)
    end

    def self.item(table_name, key, params = {})
      params[:table_name] = prefix_table(table_name)
      params[:key] = key
      connection.get_item(params)&.item
    end

    def self.update_item(table_name, key, params)
      params[:table_name] = prefix_table(table_name)
      params[:key] = key
      connection.update_item(params)
    end

    def self.attribute_value(table_name, key, attribute_path)
      alias_mapping, projection_expression = attribute_alias(attribute_path)
      params = {
        expression_attribute_names: alias_mapping,
        projection_expression: projection_expression
      }
      val = item(table_name, key, params)
      val = val.dig(*attribute_path.split('.')) if val.is_a?(Hash)
      val
    end

    # Returns alias name mapping and combined expression for dynamodb request
    # Necessary to process dynamo requests as there are certain reserved words
    # we cannot use
    # TODO: This probably could be done better...
    def self.attribute_alias(attribute_path)
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

    def self.provisioned_throughput(table_name)
      resp = connection.describe_table(table_name: prefix_table(table_name))
      resp[:table][:provisioned_throughput]
    end

    def self.read_capacity(table_name)
      provisioned_throughput(table_name)[:read_capacity_units]
    end

    def self.write_capacity(table_name)
      provisioned_throughput(table_name)[:write_capacity_units]
    end

    # Only get a limited number of these per day, be careful!
    def self.update_read_capacity(table_name, new_read_capacity)
      params = {
        provisioned_throughput: {
          read_capacity_units: new_read_capacity,
          write_capacity_units: write_capacity(table_name)
        },
        table_name: prefix_table(table_name)
      }
      connection.update_table params
    end

    # Only get a limited number of these per day, be careful!
    def self.update_write_capacity(table_name, new_write_capacity)
      params = {
        provisioned_throughput: {
          read_capacity_units: read_capacity(table_name),
          write_capacity_units: new_write_capacity
        },
        table_name: prefix_table(table_name)
      }
      connection.update_table params
    end
  end
end
