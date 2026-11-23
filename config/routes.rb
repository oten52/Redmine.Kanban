get 'projects/:project_id/kanban', :to => 'redmine_kanban#show'
post 'projects/:project_id/kanban/move', :to => 'redmine_kanban#move'
