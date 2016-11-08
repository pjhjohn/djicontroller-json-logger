class CreateEpisodes < ActiveRecord::Migration
  def change
    create_table :episodes do |t|
      t.string :name
      t.integer :timestep,      :default => 200
      t.string :control_points, :default => [].to_json
      t.string :states,         :default => [].to_json
      t.string :diff_states,    :default => [].to_json
      t.string :commands,       :default => [].to_json
      t.string :simulator_logs, :default => [].to_json

      t.timestamps null: false
    end
  end
end
