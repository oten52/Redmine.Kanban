# Redmine Kanban
# Copyright (C) 2026 Niltek Arge
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version. See the LICENSE file for details.

require_relative 'lib/redmine_kanban/board'
require_relative 'lib/redmine_kanban/saved_board'

Redmine::Plugin.register :redmine_kanban do
  name 'Kanban'
  author 'Niltek Arge'
  author_url 'https://github.com/oten52'
  description 'Sorgu sonucunu durum sütunlarında gösterir. Panolar kaydedilip paylaşılabilir.'
  version '0.3.2'
  url 'https://github.com/oten52/Redmine.Kanban'
  requires_redmine version_or_higher: '4.2'

  # The git repository folder is Redmine.Kanban. Point Redmine at this
  # directory so the plugin loads without renaming the clone.
  directory File.expand_path(__dir__)

  menu :project_menu, :redmine_kanban,
    {:controller => 'redmine_kanban', :action => 'show'},
    :caption => :redmine_kanban_menu,
    :after => :issues,
    :param => :project_id,
    :permission => :view_issues
end
