# Redmine Kanban

Adds a Kanban tab to each project. Columns are issue statuses and cards are issues.

[Türkçe](README.tr.md)

## What's new

* 0.3.1: The status-change dialog searches assignees and accepts files. See [CHANGELOG](CHANGELOG.md).

## Features

* A project tab named Kanban, next to Issues, for users who can view issues.
* Choose one or more saved issue queries. The cards are that query's current result.
* Choose which statuses appear as columns. With none selected, the open statuses are shown.
* Save the view as a shortcut. Edit, delete and change who can see it the same way as a saved query: only me, any user, or selected roles. A shortcut can also be available on all projects.
* Shortcuts are listed in the sidebar. Saving uses the same permission as saving queries. Sharing with everyone or with roles uses the public-query permission.
* Drag a card to change its status. The workflow and the edit permission are checked.
* Turn on "Ask when the status changes" to edit assignee, notes, files, dates and done ratio in a dialog. Leave it off to change the status directly.
* The board shows the 400 most recently updated matching issues.

## Required Redmine version

* 4.2.x ~ 6.x

No extra gem and no asset compilation. Saving shortcuts requires one database migration.

## Install

1. From the Redmine `plugins` directory:

```bash
git clone https://github.com/oten52/Redmine.Kanban.git
```

The directory name can stay `Redmine.Kanban`.

2. Run the plugin migration and restart Redmine.

```bash
docker exec redmine-redmine-1 bundle exec rake redmine:plugins:migrate NAME=redmine_kanban RAILS_ENV=production
docker restart redmine-redmine-1
```

Open a project. The Kanban tab is next to Issues. Select queries and statuses, then add a shortcut.

## Update

0.3.1 does not add a migration. If 0.2.0 is already migrated, pull and restart are enough. The migrate command below is safe to repeat.

```bash
cd /home/niltek/redmine/app/plugins/Redmine.Kanban
sudo -u niltek git pull
docker exec redmine-redmine-1 bundle exec rake redmine:plugins:migrate NAME=redmine_kanban RAILS_ENV=production
docker restart redmine-redmine-1
```

## Uninstall

1. Delete the `Redmine.Kanban` folder.
2. Restart Redmine.

## Author

Niltek Arge — https://github.com/oten52

## License

GNU General Public License v3.0 or later. See [LICENSE](LICENSE).

If you modify and distribute this plugin, keep the copyright notices, state your changes and
distribute your version under the same license.
