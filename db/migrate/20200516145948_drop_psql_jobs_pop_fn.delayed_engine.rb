# This migration comes from delayed_engine (originally 20120531150712)
class DropPsqlJobsPopFn < ActiveRecord::Migration[4.2]
  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP FUNCTION IF EXISTS pop_from_delayed_jobs(varchar, varchar, integer, integer, timestamp without time zone)")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
