# Redmine Kanban

Adds a Kanban tab to each project. Columns are issue statuses and cards are issues.

[Türkçe](README.tr.md)

## What's new

* 0.1.0: First release. See [CHANGELOG](CHANGELOG.md).

## Features

* A project tab named Kanban, next to Issues, for users who can view issues.
* Columns follow the project's tracker workflows. Closed statuses can be shown with a filter.
* Drag a card to change its status, or choose a status on the card. The workflow and the edit permission are checked.
* Filter by tracker, assignee, priority, version and subject.
* The board shows the 400 most recently updated matching issues.

## Required Redmine version

* 4.2.x ~ 6.x

No database migration, no extra gem and no asset compilation.

## Install

1. From the Redmine `plugins` directory:

```bash
git clone https://github.com/oten52/Redmine.Kanban.git
```

The directory name can stay `Redmine.Kanban`.

2. Restart Redmine.

Open a project. The Kanban tab is next to Issues.

## Uninstall

1. Delete the `Redmine.Kanban` folder.
2. Restart Redmine.

## Author

Niltek Arge — https://github.com/oten52

## License

GNU General Public License v3.0 or later. See [LICENSE](LICENSE).

If you modify and distribute this plugin, keep the copyright notices, state your changes and
distribute your version under the same license.
