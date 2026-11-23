# frozen_string_literal: true

class CreateRedmineKanbanBoards < ActiveRecord::Migration[5.2]
  def change
    create_table :redmine_kanban_boards do |t|
      t.integer :project_id
      t.integer :user_id, :null => false
      t.string :name, :null => false, :limit => 255
      t.string :description, :limit => 255
      t.integer :visibility, :null => false, :default => 0
      t.text :query_ids
      t.text :status_ids
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :redmine_kanban_boards, :project_id
    add_index :redmine_kanban_boards, :user_id
    add_index :redmine_kanban_boards, :visibility

    create_table :redmine_kanban_boards_roles, :id => false do |t|
      t.integer :board_id, :null => false
      t.integer :role_id, :null => false
    end
    add_index :redmine_kanban_boards_roles, [:board_id, :role_id],
              :unique => true, :name => 'redmine_kanban_boards_roles_idx'
  end
end
