require 'rake'

class Rake::Task
  def already_invoked?
    @already_invoked
  end
end

require 'erb'

class Object
  # allow database configuration to be changed during db:test:prepare
  def reset_current_config
    @current_config = nil
  end
end


class GOA::RakeTasks
  attr_reader :engine_task_namespace, :engine_root, :application_config_database_environment, :schema_format

  def initialize(engine_task_namespace = nil, options = {})
    @engine_task_namespace = engine_task_namespace || caller.first.match(/.*\/([^:.]+)/)[1]
    @engine_root = options[:engine_root] || File.join(caller.first.match(/(.*)\//)[1], '..', '..')
    @application_config_database_environment = options[:application_config_database_environment]
    @schema_format = options[:schema_format]
  end

  def add_rake_tasks()
    extend Rake::DSL

    namespace engine_task_namespace do
      # https://gist.github.com/rafaelchiti/5575309
      namespace(:db) do
        %w(drop create migrate rollback seed version schema:load schema:dump test:prepare).each do |name|
          desc "Run #{name} for #{engine_task_namespace} gem"
          task name do
            invoke_engine_task("db:#{name}")
          end
        end
      end

      task :startup do
        @orig_db = Rails.application.config.paths['db']
        @orig_db_migrate = Rails.application.config.paths['db/migrate']
        @orig_db_seeds = Rails.application.config.paths['db/seeds']
        @orig_db_config = Rails.application.config.paths['config/database']
        @orig_schema_format = ActiveRecord::Base.schema_format
        @orig_env_schema = ENV['SCHEMA']
      end

      task :setup do
        %w(db:load_config db:structure:load db:schema:load db:schema:dump).each do |name|
          Rake::Task[name].reenable
        end

        {
          'db' => 'db',
          'db/migrate' => 'db/migrate',
          'db/seeds' => 'db/seeds.rb',
          'config/database' => database_config_file_path
        }.each do |key, value|
          Rails.application.config.paths[key] = [File.join(engine_root, value)]
        end
        ActiveRecord::Base.schema_format = schema_format if schema_format

        schema_file_name = schema_format == :sql ? 'structure.sql' : 'schema.rb'
        ENV['SCHEMA'] = File.join(engine_root, 'db', schema_file_name)

        reset_current_config
        Rake::Task["db:load_config"].execute # load config after we made our changes

        @orig_connection_config = ActiveRecord::Base.connection_config if ActiveRecord::Base.connected? and @orig_connection_config.nil?
        ActiveRecord::Base.establish_connection(engine_database_config)
      end

      task :teardown do
        ActiveRecord::Base.establish_connection(@orig_connection_config) if @orig_connection_config

        {
          'db' => @orig_db,
          'db/migrate' => @orig_db_migrate,
          'db/seeds' => @orig_db_seeds,
          'config/database' => @orig_db_config
        }.each do |key, value|
          Rails.application.config.paths[key] = value
        end
        ActiveRecord::Base.schema_format = @orig_schema_format

        ENV['SCHEMA'] = @orig_env_schema

        Rake::Task["db:load_config"].tap { |t| t.execute; t.reenable } # restore original config after done

        reset_current_config
      end
    end


    # Make tasks that invoke both supply client and bomb db tasks
    %w(db:drop db:create db:migrate db:rollback db:seed db:version db:schema:load db:schema:dump db:test:prepare).each do |name|
      desc "Run #{name} for app and model gems"
      task "app:#{name}" => ["#{engine_task_namespace}:#{name}", name]

      task "#{engine_task_namespace}:#{name}" => ["#{engine_task_namespace}:startup", "#{engine_task_namespace}:setup"] do
        Rake::Task["#{engine_task_namespace}:setup"].reenable
        Rake::Task["#{engine_task_namespace}:teardown"].execute
      end
    end
  end

  private

  def engine_database_config
    @database_config ||= ::GOA::Config.database_config(engine_root, application_config_database_environment)
  end

  def database_config_file_path
    full_path = ::GOA::Config.database_config_file_path(engine_root)

    relative_path = full_path[engine_root.length..-1].gsub(/^\/?/, '')

    relative_path
  end

  def invoke_engine_task(name)
    already_invoked = Rake::Task[name].already_invoked?

    Rake::Task[name].execute # use execute to run even if run before

    Rake::Task[name].reenable unless already_invoked # reenable task if it wasn't run before our execute
  end
end