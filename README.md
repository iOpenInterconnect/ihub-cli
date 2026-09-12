# CLI for iHub
This repository is the core utility of the project iHub. 

It is designed to discover, manage, keep track of and automate open-source implementations of proprietary Apple Inc. software, such as the examples you can find below.

__As of now__, you are able to automatically install and manage various iOS-related Open Source projects. It is intended to be the core system that the future TUI will be based on.

## Key features

Usage: `ihub <command> [project] [options]`

Manage open-source projects installed by iHub.

Commands:
```  list                    List available projects.
  status <project>        Show installation status.
  install <project>       Install a project.
  uninstall <project>     Uninstall a project.
  update <project>        Update a project.
  help                    Show this help.
  --update                Update iHub itself
  --uninstall             Uninstall iHub
```

## Start
Install this project by running:

```bash
curl -fsSL raw.githubusercontent.com/iOpenInterconnect/ihub-cli/refs/heads/main/install.sh -o install.sh
bash install.sh
```

You can then run `ihub` in a new terminal window and test it out.

Feel free to open a PR or issue at any time!




This project works with UxPlay from:
https://github.com/FDH2/UxPlay

UxPlay is licensed under the GNU General Public License
v3 or later.

Apple, AirPlay, and iOS are trademarks of Apple Inc.
