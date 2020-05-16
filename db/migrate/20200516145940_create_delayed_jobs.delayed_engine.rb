# This migration comes from delayed_engine (originally 20101216224513)
class CreateDelayedJobs < ActiveRecord::Migration[4.2]
  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    raise("#{connection.adapter_name} is not supported for delayed jobs queue") unless connection.adapter_name == 'PostgreSQL'

    create_table :delayed_jobs do |table|
      # Allows some jobs to jump to the front of the queue
      table.integer  :priority, :default => 0
      # Provides for retries, but still fail eventually.
      table.integer  :attempts, :default => 0
      # YAML-encoded string of the object that will do work
      table.text     :handler, :limit => (500 * 1024)
      # reason for last failure (See Note below)
      table.text     :last_error
      # The queue that this job is in
      table.string   :queue, :default => nil
      # When to run.
      # Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime :run_at
      # Set when a client is working on this object
      table.datetime :locked_at
      # Set when all retries have failed
      table.datetime :failed_at
      # Who is working on this object (if locked)
      table.string   :locked_by

      table.timestamps
    end

    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
    add_index :delayed_jobs, [:queue], :name => 'delayed_jobs_queue'
  end

  def down
    drop_table :delayed_jobs
  end
end
