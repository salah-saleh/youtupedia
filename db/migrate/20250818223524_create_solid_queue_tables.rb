class CreateSolidQueueTables < ActiveRecord::Migration[7.1]
  def change
    # Create solid_queue_blocked_executions table for SolidQueue
    # This table tracks jobs that are blocked due to concurrency limits
    create_table :solid_queue_blocked_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
    end
    
    # Add indexes for efficient querying
    add_index :solid_queue_blocked_executions, [:concurrency_key, :priority, :job_id], name: "index_solid_queue_blocked_executions_for_release"
    add_index :solid_queue_blocked_executions, [:expires_at, :concurrency_key], name: "index_solid_queue_blocked_executions_for_maintenance"
    add_index :solid_queue_blocked_executions, [:job_id], name: "index_solid_queue_blocked_executions_on_job_id", unique: true

    # Create solid_queue_claimed_executions table for SolidQueue
    # This table tracks jobs that have been claimed by a worker process
    create_table :solid_queue_claimed_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.bigint :process_id
      t.datetime :created_at, null: false
    end
    
    # Add indexes for efficient querying
    add_index :solid_queue_claimed_executions, [:job_id], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    add_index :solid_queue_claimed_executions, [:process_id, :job_id], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"

    # Create solid_queue_failed_executions table for SolidQueue
    # This table tracks jobs that have failed execution
    create_table :solid_queue_failed_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.text :error
      t.datetime :created_at, null: false
    end
    
    # Add index for efficient querying
    add_index :solid_queue_failed_executions, [:job_id], name: "index_solid_queue_failed_executions_on_job_id", unique: true

    # Create solid_queue_jobs table for SolidQueue
    # This is the main table that stores all job information
    create_table :solid_queue_jobs, force: :cascade do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    # Add indexes for efficient querying and filtering
    add_index :solid_queue_jobs, [:active_job_id], name: "index_solid_queue_jobs_on_active_job_id"
    add_index :solid_queue_jobs, [:class_name], name: "index_solid_queue_jobs_on_class_name"
    add_index :solid_queue_jobs, [:finished_at], name: "index_solid_queue_jobs_on_finished_at"
    add_index :solid_queue_jobs, [:queue_name, :finished_at], name: "index_solid_queue_jobs_for_filtering"
    add_index :solid_queue_jobs, [:scheduled_at, :finished_at], name: "index_solid_queue_jobs_for_alerting"

    # Create solid_queue_pauses table for SolidQueue
    # This table tracks paused queues
    create_table :solid_queue_pauses, force: :cascade do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false
    end
    
    # Add unique index on queue_name
    add_index :solid_queue_pauses, [:queue_name], name: "index_solid_queue_pauses_on_queue_name", unique: true

    # Create solid_queue_processes table for SolidQueue
    # This table tracks worker processes
    create_table :solid_queue_processes, force: :cascade do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname
      t.text :metadata
      t.datetime :created_at, null: false
      t.string :name, null: false
    end
    
    # Add indexes for efficient querying and monitoring
    add_index :solid_queue_processes, [:last_heartbeat_at], name: "index_solid_queue_processes_on_last_heartbeat_at"
    add_index :solid_queue_processes, [:name, :supervisor_id], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    add_index :solid_queue_processes, [:supervisor_id], name: "index_solid_queue_processes_on_supervisor_id"

    # Create solid_queue_ready_executions table for SolidQueue
    # This table tracks jobs ready for execution
    create_table :solid_queue_ready_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false
    end
    
    # Add indexes for efficient polling and execution
    add_index :solid_queue_ready_executions, [:job_id], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    add_index :solid_queue_ready_executions, [:priority, :job_id], name: "index_solid_queue_ready_executions_poll_all"
    add_index :solid_queue_ready_executions, [:queue_name, :priority, :job_id], name: "index_solid_queue_ready_executions_poll_by_queue"

    # Create solid_queue_recurring_executions table for SolidQueue
    # This table tracks recurring job executions
    create_table :solid_queue_recurring_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false
    end
    
    # Add indexes for efficient querying
    add_index :solid_queue_recurring_executions, [:job_id], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    add_index :solid_queue_recurring_executions, [:task_key, :run_at], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true

    # Create solid_queue_recurring_tasks table for SolidQueue
    # This table stores recurring task definitions
    create_table :solid_queue_recurring_tasks, force: :cascade do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, limit: 2048
      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority, default: 0
      t.boolean :static, default: true, null: false
      t.text :description
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    # Add indexes for efficient querying
    add_index :solid_queue_recurring_tasks, [:key], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    add_index :solid_queue_recurring_tasks, [:static], name: "index_solid_queue_recurring_tasks_on_static"

    # Create solid_queue_scheduled_executions table for SolidQueue
    # This table tracks scheduled job executions
    create_table :solid_queue_scheduled_executions, force: :cascade do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false
    end
    
    # Add indexes for efficient dispatching
    add_index :solid_queue_scheduled_executions, [:job_id], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    add_index :solid_queue_scheduled_executions, [:scheduled_at, :priority, :job_id], name: "index_solid_queue_scheduled_executions_dispatch_all"

    # Create solid_queue_semaphores table for SolidQueue
    # This table manages concurrency control
    create_table :solid_queue_semaphores, force: :cascade do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    # Add indexes for efficient querying and cleanup
    add_index :solid_queue_semaphores, [:expires_at], name: "index_solid_queue_semaphores_on_expires_at"
    add_index :solid_queue_semaphores, [:key, :value], name: "index_solid_queue_semaphores_on_key_and_value"
    add_index :solid_queue_semaphores, [:key], name: "index_solid_queue_semaphores_on_key", unique: true

    # Add foreign key constraints for referential integrity
    add_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end
