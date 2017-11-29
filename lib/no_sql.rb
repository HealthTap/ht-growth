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

    def self.put_item(table_name, item)
      table_name = App.settings.nosql['table_prefix'] + table_name
      connection.put_item(table_name: table_name, item: item)
    end

    def self.get_item(table_name, key, params = {})
      params[:table_name] = App.settings.nosql['table_prefix'] + table_name
      params[:key] = key
      connection.get_item(params)&.item
    end

    def self.update_item(table_name, key, params)
      params[:table_name] = App.settings.nosql['table_prefix'] + table_name
      params[:key] = key
      connection.update_item(params)
    end
  end
end
