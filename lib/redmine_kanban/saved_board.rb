# frozen_string_literal: true

module RedmineKanban
  class SavedBoard < ActiveRecord::Base
    self.table_name = 'redmine_kanban_boards'

    VISIBILITY_PRIVATE = 0
    VISIBILITY_ROLES = 1
    VISIBILITY_PUBLIC = 2

    belongs_to :project, :optional => true
    belongs_to :user
    has_and_belongs_to_many :roles,
      :join_table => 'redmine_kanban_boards_roles',
      :foreign_key => 'board_id',
      :association_foreign_key => 'role_id'

    validates :name, :presence => true, :length => {:maximum => 255}
    validates :description, :length => {:maximum => 255}
    validates :user_id, :presence => true
    validates :visibility, :inclusion => {:in => [VISIBILITY_PRIVATE, VISIBILITY_ROLES, VISIBILITY_PUBLIC]}
    validate :roles_selected_when_shared

    before_create :stamp_created
    before_save :stamp_updated

    def self.table_ready?
      connection.data_source_exists?(table_name)
    rescue StandardError
      false
    end

    def self.visible_on(project, user = User.current)
      user ||= User.current
      table = table_name
      allowed = Project.allowed_to_condition(user, :view_issues)
      scope = joins("LEFT OUTER JOIN #{Project.table_name} ON #{table}.project_id = #{Project.table_name}.id").
        where("#{table}.project_id IS NULL OR (#{allowed})").
        where("#{table}.project_id IS NULL OR #{table}.project_id = ?", project.id)

      if user.admin?
        scope.where("#{table}.visibility <> ? OR #{table}.user_id = ?", VISIBILITY_PRIVATE, user.id)
      elsif user.memberships.any?
        scope.where(
          "#{table}.visibility = ? OR #{table}.user_id = ? OR (#{table}.visibility = ? AND EXISTS (" \
          "SELECT 1 FROM redmine_kanban_boards_roles kr " \
          "INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = kr.role_id " \
          "INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ? " \
          "INNER JOIN #{Project.table_name} p ON p.id = m.project_id AND p.status <> ? " \
          "WHERE kr.board_id = #{table}.id AND (#{table}.project_id IS NULL OR #{table}.project_id = m.project_id)))",
          VISIBILITY_PUBLIC, user.id, VISIBILITY_ROLES, user.id, Project::STATUS_ARCHIVED
        )
      elsif user.logged?
        scope.where("#{table}.visibility = ? OR #{table}.user_id = ?", VISIBILITY_PUBLIC, user.id)
      else
        scope.where("#{table}.visibility = ?", VISIBILITY_PUBLIC)
      end
    end

    def query_id_list
      RedmineKanban.integer_list(query_ids.to_s.split(','), 20)
    end

    def query_id_list=(ids)
      self.query_ids = RedmineKanban.integer_list(ids, 20).join(',')
    end

    def status_id_list
      RedmineKanban.integer_list(status_ids.to_s.split(','), 40)
    end

    def status_id_list=(ids)
      self.status_ids = RedmineKanban.integer_list(ids, 40).join(',')
    end

    def editable_by?(editor)
      return false unless editor
      return true if editor.admin? || (visibility == VISIBILITY_PRIVATE && user_id == editor.id)

      visibility != VISIBILITY_PRIVATE && project_id.present? &&
        editor.allowed_to?(:manage_public_queries, project)
    end

    def private?
      visibility == VISIBILITY_PRIVATE
    end

    private

    def roles_selected_when_shared
      return unless visibility == VISIBILITY_ROLES
      return if roles.any?

      errors.add(:base, I18n.t(:redmine_kanban_roles_required))
    end

    def stamp_created
      self.created_on ||= Time.now
    end

    def stamp_updated
      self.updated_on = Time.now
    end
  end
end
