# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161109131827) do

  create_table "episodes", force: :cascade do |t|
    t.string   "name"
    t.integer  "timestep",       default: 200
    t.string   "control_points", default: "[]"
    t.string   "states",         default: "[]"
    t.string   "diff_states",    default: "[]"
    t.string   "commands",       default: "[]"
    t.string   "simulator_logs", default: "[]"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "trajectory_optimizations", force: :cascade do |t|
    t.string   "episode_name"
    t.integer  "episode_timestep"
    t.string   "episode_control_points"
    t.string   "episode_states"
    t.string   "episode_diff_states"
    t.string   "episode_commands"
    t.string   "control_points_list"
    t.string   "commands_list"
    t.string   "simulator_log_list",      default: "[]"
    t.integer  "max_iteration_count",     default: 10
    t.integer  "current_iteration_index", default: 0
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

end
