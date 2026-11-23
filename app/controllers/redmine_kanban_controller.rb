# frozen_string_literal: true

class RedmineKanbanController < ApplicationController
  before_action :find_project_by_project_id
  before_action :require_kanban_access
  before_action :require_saved_board, :only => [:create, :update, :destroy]
  helper_method :kanban_allowed_statuses, :kanban_can_save?, :kanban_can_share?

  def show
    forget_board if params[:clear].present?
    load_page
  end

  def create
    board = RedmineKanban::SavedBoard.new
    board.user = User.current
    if store_board(board)
      remember_board(board)
      flash[:notice] = l(:notice_successful_create)
      redirect_to(saved_location(board))
    else
      @form_board = board
      load_page
      render :show
    end
  end

  def update
    board = editable_board
    return unless board

    if store_board(board)
      remember_board(board)
      flash[:notice] = l(:notice_successful_update)
      redirect_to(saved_location(board))
    else
      @form_board = board
      @saved = board
      load_page
      render :show
    end
  end

  def destroy
    board = editable_board
    return unless board

    board.destroy
    forget_board if session[session_key].to_s == board.id.to_s
    flash[:notice] = l(:notice_successful_delete)
    redirect_to(show_path)
  end

  def move
    issue = @project.issues.visible.find_by(:id => params[:issue_id].to_i)
    status = IssueStatus.find_by(:id => params[:status_id].to_i)
    unless issue && status
      return fail_move(l(:redmine_kanban_not_found))
    end

    if issue.status_id != status.id
      allowed = issue.new_statuses_allowed_to(User.current)
      unless allowed.include?(status)
        return fail_move(l(:redmine_kanban_transition_denied))
      end
      issue.init_journal(User.current)
      issue.status = status
      unless issue.save
        return fail_move(issue.errors.full_messages.join(', '))
      end
    end

    if request.xhr?
      render :json => {:ok => true}
    else
      redirect_to(show_location)
    end
  end

  private

  def require_kanban_access
    permission = action_name == 'move' ? :edit_issues : :view_issues
    unless User.current.allowed_to?(permission, @project)
      deny_access
      return false
    end
    true
  end

  def require_saved_board
    unless kanban_can_save?
      deny_access
      return false
    end
    if RedmineKanban::SavedBoard.table_ready?
      true
    else
      flash[:error] = l(:redmine_kanban_migrate)
      redirect_to(show_path)
      false
    end
  end

  def load_page
    @saved ||= locate_saved
    remember_board(@saved) if @saved && params[:clear].blank?
    @form_board ||= build_form_board
    @board = RedmineKanban::Board.new(@project, params, @saved)
    @issues = @board.issues
    @statuses = @board.statuses
    @grouped = @board.issues_by_status
    @can_edit = User.current.allowed_to?(:edit_issues, @project)
    @boards_ready = RedmineKanban::SavedBoard.table_ready?
    @shortcuts = load_shortcuts
  end

  def locate_saved
    return nil unless RedmineKanban::SavedBoard.table_ready?

    requested = params[:board_id].presence
    requested ||= session[session_key] if params[:configured].blank? && params[:clear].blank? && params[:save].blank?
    return nil if requested.blank?

    found = RedmineKanban::SavedBoard.visible_on(@project).find_by(:id => requested.to_i)
    @missing_board = found.nil? && params[:board_id].present?
    found
  end

  def build_form_board
    return nil unless kanban_can_save? && RedmineKanban::SavedBoard.table_ready?

    if params[:edit].present? && @saved && @saved.editable_by?(User.current)
      @saved
    elsif params[:save].present?
      board = RedmineKanban::SavedBoard.new
      board.user = User.current
      board.project = @project
      board.visibility = RedmineKanban::SavedBoard::VISIBILITY_PRIVATE
      board
    end
  end

  def load_shortcuts
    return [] unless RedmineKanban::SavedBoard.table_ready?

    RedmineKanban::SavedBoard.visible_on(@project).order("#{RedmineKanban::SavedBoard.table_name}.name ASC").to_a
  rescue ActiveRecord::ActiveRecordError
    @needs_migration = true
    []
  end

  def editable_board
    board = RedmineKanban::SavedBoard.visible_on(@project).find_by(:id => params[:id].to_i)
    unless board
      render_404
      return nil
    end
    unless board.editable_by?(User.current)
      render_403
      return nil
    end
    board
  end

  def store_board(board)
    stored = false
    RedmineKanban::SavedBoard.transaction do
      assign_board(board)
      stored = board.save
      raise ActiveRecord::Rollback unless stored
    end
    stored
  end

  def assign_board(board)
    board.name = params[:name].to_s.strip.slice(0, 255)
    board.description = params[:description].to_s.strip.slice(0, 255)
    board.visibility = sanitized_visibility
    board.project = board_project(board)
    preview = RedmineKanban::Board.new(@project, {
      :configured => '1',
      :query_ids => params[:query_ids],
      :status_ids => params[:status_ids]
    })
    board.query_id_list = preview.query_ids
    board.status_id_list = preview.status_ids
    if board.visibility == RedmineKanban::SavedBoard::VISIBILITY_ROLES
      board.roles = Role.givable.where(:id => RedmineKanban.integer_list(params[:role_ids], 50)).to_a
    else
      board.roles = []
    end
    board
  end

  def sanitized_visibility
    value = params[:visibility].to_i
    allowed = [RedmineKanban::SavedBoard::VISIBILITY_PRIVATE]
    if kanban_can_share?
      allowed << RedmineKanban::SavedBoard::VISIBILITY_ROLES
      allowed << RedmineKanban::SavedBoard::VISIBILITY_PUBLIC
    end
    allowed.include?(value) ? value : RedmineKanban::SavedBoard::VISIBILITY_PRIVATE
  end

  def board_project(board)
    return @project unless params[:board_is_for_all].to_s == '1'
    return nil if User.current.admin? || board.visibility == RedmineKanban::SavedBoard::VISIBILITY_PRIVATE

    @project
  end

  def kanban_can_save?
    User.current.allowed_to?(:save_queries, @project)
  end

  def kanban_can_share?
    User.current.admin? || User.current.allowed_to?(:manage_public_queries, @project)
  end

  def remember_board(board)
    session[session_key] = board.id
  end

  def forget_board
    session.delete(session_key)
  end

  def session_key
    "redmine_kanban_board_#{@project.id}"
  end

  def saved_location(board)
    url_for(
      :controller => 'redmine_kanban',
      :action => 'show',
      :project_id => @project,
      :board_id => board.id,
      :only_path => true
    )
  end

  def show_path
    url_for(:controller => 'redmine_kanban', :action => 'show', :project_id => @project, :only_path => true)
  end

  def kanban_allowed_statuses(issue)
    key = [
      issue.tracker_id,
      issue.status_id,
      issue.author_id == User.current.id,
      issue.assigned_to_id == User.current.id
    ]
    @allowed_statuses ||= {}
    @allowed_statuses[key] ||= begin
      list = issue.new_statuses_allowed_to(User.current).to_a
      list << issue.status unless list.include?(issue.status)
      list
    end
  end

  def fail_move(message)
    if request.xhr?
      render :json => {:ok => false, :error => message}, :status => 422
    else
      flash[:error] = message.to_s.slice(0, 300)
      redirect_to(show_location)
    end
  end

  def show_location
    url_for({
      :controller => 'redmine_kanban',
      :action => 'show',
      :project_id => @project,
      :only_path => true
    }.merge(RedmineKanban::Board.new(@project, params).redirect_params))
  end
end
