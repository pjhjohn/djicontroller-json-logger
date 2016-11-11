class CreateTrajectoryOptimizations < ActiveRecord::Migration
  def change
    create_table :trajectory_optimizations do |t|
      t.integer :episode_id
      t.string :control_points_list,      :default => [].to_json
      t.string :states_list
      t.string :commands_list
      t.string :simulator_log_list,       :default => [].to_json
      t.integer :max_iteration_count,     :default => 10
      t.integer :current_iteration_index, :default => 0
      t.timestamps null: false
    end
  end
end
