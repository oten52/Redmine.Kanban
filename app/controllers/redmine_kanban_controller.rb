# frozen_string_literal: true

class RedmineKanbanController < ApplicationController
  before_action :find_project_by_project_id
  before_action :require_kanban_access
  helper_method :kanban_allowed_statuses, :kanban_filters

  def show
    @board = RedmineKanban::Board.new(@project, params)
    @issues = @board.issues
    @statuses = @board.statuses
    @grouped = @board.issues_by_status
    @can_edit = User.current.allowed_to?(:edit_issues, @project)
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

  def kanban_filters
    @board ? @board.filters : {}
  end

  def fail_move(message)
    if request.xhr?
      render :json => {:ok => false, :error => message}, :status => 422
    else
      flash[:error] = message
      redirect_to(show_location)
    end
  end

  def show_location
    url_for({
      :controller => 'redmine_kanban',
      :action => 'show',
      :project_id => @project,
      :only_path => true
    }.merge(RedmineKanban::Board.new(@project, params).filters))
  end
end
