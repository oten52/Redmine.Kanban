# frozen_string_literal: true

module RedmineKanban
  def self.integer_list(value, limit)
    values = value.is_a?(Array) ? value : value.to_s.split(',')
    values.map(&:to_s).select {|item| item.match?(/\A\d+\z/)}.map(&:to_i).uniq.first(limit)
  end

  class Board
    LIMIT = 400

    attr_reader :query_failed

    def initialize(project, params, saved = nil)
      @project = project
      @params = params || {}
      @saved = saved
      @query_failed = false
    end

    def query_ids
      @query_ids ||= begin
        raw = configured? ? RedmineKanban.integer_list(@params[:query_ids], 20) : Array(@saved && @saved.query_id_list)
        allowed = visible_queries.map(&:id)
        raw.select {|id| allowed.include?(id)}.first(20)
      end
    end

    def status_ids
      @status_ids ||= begin
        available = available_status_ids
        chosen = if configured?
                   RedmineKanban.integer_list(@params[:status_ids], 40)
                 elsif @saved
                   @saved.status_id_list
                 else
                   []
                 end
        chosen = chosen.select {|id| available.include?(id)}
        chosen = default_status_ids if chosen.empty?
        chosen
      end
    end

    def statuses
      @statuses ||= begin
        found = IssueStatus.where(:id => status_ids).index_by(&:id)
        status_ids.map {|id| found[id]}.compact
      end
    end

    def status_choices
      chosen = {}
      status_ids.each {|id| chosen[id] = true}
      statuses + available_statuses.reject {|status| chosen[status.id]}
    end

    def available_statuses
      @available_statuses ||= begin
        ids = available_status_ids
        found = IssueStatus.where(:id => ids).sorted.to_a
        found = IssueStatus.sorted.to_a if found.empty?
        found
      end
    end

    def visible_queries
      @visible_queries ||= begin
        table = IssueQuery.table_name
        IssueQuery.visible.
          where("#{table}.project_id IS NULL OR #{table}.project_id = ?", @project.id).
          order("#{table}.name ASC").
          to_a.
          reject {|query| query.name.to_s == '_'}
      rescue ActiveRecord::ActiveRecordError
        []
      end
    end

    def selected_queries
      @selected_queries ||= begin
        by_id = visible_queries.index_by(&:id)
        query_ids.map {|id| by_id[id]}.compact
      end
    end

    def issues
      @issues ||= load_issues
    end

    def assigners
      @assigners ||= load_assigners
    end

    def issues_by_status
      @issues_by_status ||= begin
        grouped = Hash.new {|hash, key| hash[key] = []}
        issues.each {|issue| grouped[issue.status_id] << issue}
        grouped
      end
    end

    def truncated?
      @truncated
    end

    def differs?
      return false unless @saved && configured?

      @saved.query_id_list.sort != query_ids.sort || @saved.status_id_list != status_ids
    end

    def redirect_params
      @redirect_params ||= begin
        result = {}
        board_id = @saved ? @saved.id : @params[:board_id]
        result[:board_id] = board_id.to_i if board_id.to_s.match?(/\A\d+\z/)
        result[:configured] = '1'
        result[:query_ids] = query_ids
        result[:status_ids] = status_ids
        result
      end
    end

    private

    def configured?
      @params[:configured].to_s == '1' || @params[:query_ids].present? || @params[:status_ids].present?
    end

    def available_status_ids
      @available_status_ids ||= begin
        tracker_ids = @project.trackers.map(&:id)
        ids = []
        if tracker_ids.any? && defined?(WorkflowTransition)
          WorkflowTransition.where(:tracker_id => tracker_ids).pluck(:old_status_id, :new_status_id).each do |old_id, new_id|
            ids << old_id
            ids << new_id
          end
        end
        ids.concat(@project.issues.unscope(:order).distinct.pluck(:status_id))
        ids = ids.compact.uniq
        ids = IssueStatus.pluck(:id) if ids.empty?
        ids
      end
    end

    def default_status_ids
      open_ids = IssueStatus.where(:id => available_status_ids, :is_closed => false).sorted.pluck(:id)
      open_ids = available_status_ids if open_ids.empty?
      open_ids
    end

    def load_issues
      scope = @project.issues.visible
      if selected_queries.any?
        ids = selected_queries.flat_map {|query| ids_for(query)}.uniq.first(LIMIT)
        scope = scope.where(:id => ids)
      end
      scope = scope.where(:status_id => status_ids) if status_ids.any?
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

    def load_assigners
      assigned = issues.select {|issue| issue.assigned_to_id.present?}
      return {} if assigned.empty?

      history = Hash.new {|hash, key| hash[key] = []}
      assignment_rows(assigned.map(&:id)).each do |issue_id, user_id, value|
        history[issue_id] << [user_id, value.to_s]
      end

      chosen = {}
      user_ids = []
      assigned.each do |issue|
        wanted = issue.assigned_to_id.to_s
        user_id = nil
        history[issue.id].each do |actor_id, value|
          user_id = actor_id if value == wanted
        end
        user_id ||= issue.author_id
        chosen[issue.id] = user_id
        user_ids << user_id
      end

      users = User.where(:id => user_ids.compact.uniq).index_by(&:id)
      chosen.each_with_object({}) do |(issue_id, user_id), result|
        result[issue_id] = users[user_id] if users[user_id]
      end
    rescue ActiveRecord::ActiveRecordError
      {}
    end

    def assignment_rows(ids)
      return [] if ids.empty? || !defined?(JournalDetail)

      JournalDetail.joins(:journal).
        where("#{Journal.table_name}.journalized_type = ? AND #{Journal.table_name}.journalized_id IN (?)", 'Issue', ids).
        where(:property => 'attr', :prop_key => 'assigned_to_id').
        order("#{Journal.table_name}.id ASC").
        pluck("#{Journal.table_name}.journalized_id", "#{Journal.table_name}.user_id", "#{JournalDetail.table_name}.value")
    rescue ActiveRecord::ActiveRecordError
      []
    end

    def ids_for(query)
      query.project = @project
      unless query.valid?
        @query_failed = true
        return []
      end

      relation = if query.respond_to?(:base_scope, true)
                   query.send(:base_scope)
                 else
                   sql = query.statement
                   scope = Issue.visible.joins(:status, :project)
                   sql.present? ? scope.where(sql) : scope
                 end
      relation.reorder(nil).limit(LIMIT).pluck("#{Issue.table_name}.id")
    rescue ActiveRecord::StatementInvalid, ::Query::StatementInvalid
      @query_failed = true
      []
    end
  end
end
