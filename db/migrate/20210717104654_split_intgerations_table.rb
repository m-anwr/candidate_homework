class SplitIntgerationsTable < ActiveRecord::Migration[5.2]
  def up
    create_table :connections do |t|
      t.belongs_to :integration, foreign_key: true
      t.jsonb :auth, null: false
      t.jsonb :path, null: false

      t.timestamps
    end

    create_table :field_mappings do |t|
      t.belongs_to :connection, foreign_key: true
      t.string :local_field, null: false
      t.string :external_field, null: false

      t.timestamps
    end

    # move associated data into new tables
    say_with_time "De-Serializing data in 'config' column into 'connections' and 'field_mappings' tables" do
      Integration.all.each do |integration|
        integration.config['connections'].each do |connection_hash|
          # create associated connection
          connection = integration.connections.create(
            auth: connection_hash['auth'], path: connection_hash['path']
          )

          # create field mappings associated to connection
          connection_hash['field_mapping'].each do |field_mapping_arr|
            connection.field_mappings.create(
              local_field: field_mapping_arr[0], external_field: field_mapping_arr[1]
            )
          end
        end
      end
    end

    remove_column :integrations, :config
  end

  def down
    add_column :integrations, :config, :jsonb

    say_with_time "Serializing data in 'connections' and 'field_mappings' tables into 'config' column" do
      Integration.all.each do |integration|
        integration.config = { 'connections' => [] }

        integration.connections.each do |connection|
          connection_hash = {}

          connection_hash['auth'] = connection.auth
          connection_hash['path'] = connection.path
          
          connection_hash['field_mapping'] = []

          connection.field_mappings.each do |field_mapping|
            connection_hash['field_mapping'] << [
              field_mapping.local_field, field_mapping.external_field
            ]
          end

          integration.config['connections'] << connection_hash
        end

        integration.save!
      end
    end

    # remove FieldMappings and Connections tables
    drop_table :field_mappings
    drop_table :connections
  end
end
