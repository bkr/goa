begin
  require 'database_cleaner'
  require 'database_cleaner/active_record/truncation'
  require 'database_cleaner/active_record/transaction'
rescue LoadError => e
  raise LoadError, "You must have the DatabaseCleaner Gem available to require 'goa/database_cleaner'"
end

module GOA
  class DatabaseCleaner
    class Truncation < ::DatabaseCleaner::ActiveRecord::Truncation
      def initialize(connection_class)
        @connection_class = connection_class
        super()
      end

      def connection_klass
        @connection_class
      end
    end

    class Transaction < ::DatabaseCleaner::ActiveRecord::Transaction
      def initialize(connection_class)
        @connection_class = connection_class
        super()
      end

      def connection_klass
        @connection_class
      end
    end

    class << self
      def truncate_database(connection_class)
        ::GOA::DatabaseCleaner::Truncation.new(connection_class).clean
      end

      def begin_transaction(connection_class)
        ::GOA::DatabaseCleaner::Transaction.new(connection_class).start
      end

      def end_transaction(connection_class)
        ::GOA::DatabaseCleaner::Transaction.new(connection_class).clean
      end
    end
  end
end