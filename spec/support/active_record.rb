require 'active_record'
require 'database_cleaner'
require 'pathname'

ActiveRecord::Base.logger = Logger.new \
  Pathname.new(__dir__).join('../../log/active_record.log').to_s

ActiveRecord::Base.establish_connection adapter: 'sqlite3',
                                        database:  ':memory:'

ActiveRecord::Schema.define do
  create_table :balloons do |table|
    table.column :color, :string
    table.column :size, :string
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    # Use truncation so we can test transaction behavior
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each, db: true) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
