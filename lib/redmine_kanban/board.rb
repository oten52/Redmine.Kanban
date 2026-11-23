# frozen_string_literal: true

module RedmineKanban
  class Board
    LIMIT = 400

    def initialize(project, params)
      @project = project
      @params = params
    end

    def show_closed?
      @params[:closed].to_s == '1'
    end

    def statuses
      @statuses ||= begin
        found = IssueStatus.where(:id => status_ids).sorted.to_a
        found = IssueStatus.sorted.to_a if found.empty?
        found.reject!(&:is_closed?) unless show_closed?
        found
      end
    end

    def issues
      @issues ||= load_issues
    end

    def issues_by_status
      @issues_by_status ||= begin
        grouped = Hash.new { |hash, key| hash[key] = [] }
        issues.each { |issue| grouped[issue.status_id] << issue }
        grouped
      end
    end

    def truncated?
      @truncated
    end

    def filters
      {
        'tracker_id' => integer_param(:tracker_id),
        'assigned_to_id' => assigned_param,
        'priority_id' => integer_param(:priority_id),
        'fixed_version_id' => integer_param(:fixed_version_id),
        'q' => query_param,
        'closed' => (show_closed? ? '1' : nil)
      }.reject { |_key, value| value.blank? }
    end

    private

    def load_issues
      scope = @project.issues.visible
      scope = scope.open unless show_closed?
      scope = scope.where(:tracker_id => filters['tracker_id']) if filters['tracker_id']
      scope = scope.where(:priority_id => filters['priority_id']) if filters['priority_id']
      scope = scope.where(:fixed_version_id => filters['fixed_version_id']) if filters['fixed_version_id']
      scope = assigned_scope(scope)
      if filters['q']
        scope = scope.where(
          "LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)",
          "%#{filters['q']}%"
        )
      end
      rows = scope.order("#{Issue.table_name}.updated_on DESC").
        includes(:status, :assigned_to, :priority, :tracker, :fixed_version).
        limit(LIMIT + 1).to_a
      @truncated = rows.size > LIMIT
      rows = rows.first(LIMIT)
      rows.sort_by! do |issue|
        priority = issue.priority ? -issue.priority.position.to_i : 0
        updated = issue.updated_on ? -issue.updated_on.to_i : 0
        [priority, updated]
      end
      rows
    end

    def assigned_scope(scope)
      value = filters['assigned_to_id']
      return scope if value.blank?
      return scope.where(:assigned_to_id => nil) if value == 'none'
      return scope.where(:assigned_to_id => ::User.current.id) if value == 'me'

      scope.where(:assigned_to_id => value.to_i)
    end

    def status_ids
      tracker_ids = @project.trackers.map(&:id)
      ids = []
      if tracker_ids.any?
        WorkflowTransition.where(:tracker_id => tracker_ids).pluck(:old_status_id, :new_status_id).each do |old_id, new_id|
          ids << old_id
          ids << new_id
        end
      end
      ids.concat(@project.issues.pluck(:status_id))
      ids.compact.uniq
    end

    def integer_param(key)
      value = @params[key].to_s
      return nil unless value =~ /\A\d+\z/

      value
    end

    def assigned_param
      value = @params[:assigned_to_id].to_s
      return value if value == 'me' || value == 'none'
      return value if value =~ /\A\d+\z/

      nil
    end

    def query_param
      value = @params[:q].to_s.strip.gsub('%', '').gsub('_', '')
      return nil if value.blank?

      value.slice(0, 80)
    end
  end
end
