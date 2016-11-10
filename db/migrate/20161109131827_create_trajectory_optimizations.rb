class CreateTrajectoryOptimizations < ActiveRecord::Migration
  def change
    create_table :trajectory_optimizations do |t|
      # Episode Data
      t.string :episode_name
      t.integer :episode_timestep
      t.string :episode_control_points
      t.string :episode_states
      t.string :episode_diff_states
      t.string :episode_commands
      
      # Trajectory Optimization Iteration
      t.string :control_points_list
      t.string :commands_list
      t.string :simulator_log_list,       :default => [].to_json
      t.integer :max_iteration_count,     :default => 10
      t.integer :current_iteration_index, :default => 0
      t.timestamps null: false
    end
  end
end
