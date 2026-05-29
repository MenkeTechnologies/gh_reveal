```
  ____ _   _   ____  _______     _______    _    _
 / ___| | | | |  _ \| ____\ \   / / ____|  / \  | |
| |  _| |_| | | |_) |  _|  \ \ / /|  _|   / _ \ | |
| |_| |  _  | |  _ <| |___  \ V / | |___ / ___ \| |___
 \____|_| |_| |_| \_\_____|  \_/  |_____/_/   \_\_____|
```

<p align="center">
<code>// CWD → git remote → default browser. ONE COMMAND. ZERO MOUSE.</code>
</p>

---

[![All Contributors](https://img.shields.io/badge/all_contributors-2-ff2a6d.svg?style=flat-square)](#contributors)
[![Tag](https://img.shields.io/badge/tag-v0.1.0-39ff14.svg)](https://github.com/MenkeTechnologies/gh_reveal/tags)
[![Shell](https://img.shields.io/badge/shell-zsh%20%7C%20bash-05d9e8.svg)](#install-for-zinit)
[![Loader](https://img.shields.io/badge/loader-zinit%20%7C%20omz%20%7C%20brew-d300c5.svg)](#install-with-homebrew-macintosh-computers)

### `[SIGNAL // OPEN THE PROJECT IN THE BROWSER WITHOUT LEAVING THE TERMINAL]`

> *// jacking your shell into the GitHub / GitLab tab without `cmd-tab`, `cmd-t`, `cmd-l`, paste //*

---

## `> SYSTEM OVERVIEW`

`reveal` is a tiny shell util: `cd` into any git project, type `reveal`, your default browser opens the project page. Reads `git remote -v` and pipes every matching URL to `open` (macOS) / `xdg-open` (Linux). Filter by remote name (`reveal origin`, `reveal gitlab`) or hit them all at once.

Built on top of `md-command-line/gh_reveal`; MenkeTechnologies' fork ships as a zinit/omz plugin for zpwr-tier setups.

## Install with Homebrew (macintosh computers):
```
brew tap md-command-line/taps &&
brew install reveal;
```

### To see additional taps checkout:
- https://github.com/md-command-line/homebrew-taps
- https://github.com/MenkeTechnologies/homebrew-taps

## Implementation

`reveal`

<b>want to reveal all of your projects in a given directory?</b><br/>
`for d in ./*/ ; do (cd "$d" && echo "$d" && reveal); done`<br/>

<b>or as with my environment  maybe all of your projects are in a folder that is subdivided by category folders.</b><br/>
`for d in ./*/ ; do (cd "$d" && echo "$d" &&  for p in ./*/ ; do (cd "$p" && echo "$p" && reveal); done); done`

![reveal gif](https://github.com/MichaelDimmitt/assets_used_by_other_repos/blob/master/assets/how_reveal_works_my_environment.gif)

## Additional Examples
Reveal takes a <b>single command line argument</b>.
<br>This argument is the <b>remote</b> you would like to open for the current directory git project.
<br>If no <b>remote</b> is specified it will reveal all remotes on the project in the browser.
<br>For most users this is just the one <b>remote</b> either <b>gitlab</b> or github (<b>origin</b>).

1) `reveal origin`
2) `reveal gitlab`
3) `reveal <your remote name here>`

Not sure what <b>remote</b> means? (context .git)
<br>cd into your git project and type `git remote -v`


## How does it work?
through the use of command:
```
git remote -v
```
gather's all <b>remotes</b> for project
<br>and proceeds to  filter the output into url's
<br>piping each as a unique url opens all the stuff.

## Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load md-command-line/gh_reveal
```

## Install as oh-my-zsh plugin
```bash
git clone https://github.com/md-command-line/gh_reveal.git ~/.oh-my-zsh/custom/plugins/gh_reveal
```
add gh_reveal to plugins array in `~/.zshrc` like so
`plugins=(gh_reveal git zsh-more-completions)`


## Alternative install/uninstall experience:
Clone and cd into the project:
```bash
git clone https://github.com/md-command-line/gh_reveal.git && cd gh_reveal;
```

install
```bash
./install.sh;
```

uninstall
```bash
./uninstall.sh
```


## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table>
  <tr>
    <td align="center"><a href="https://twitter.com/m_dimmitt"><img src="https://avatars1.githubusercontent.com/u/11463275?v=4" width="100px;" alt="MichaelDimmitt"/><br /><sub><b>MichaelDimmitt</b></sub></a><br /><a href="#infra-MichaelDimmitt" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/md-command-line/gh_reveal/commits?author=MichaelDimmitt" title="Documentation">📖</a> <a href="https://github.com/md-command-line/gh_reveal/commits?author=MichaelDimmitt" title="Code">💻</a></td>
    <td align="center"><a href="http://www.jakobmenke.com"><img src="https://avatars0.githubusercontent.com/u/18195247?v=4" width="100px;" alt="Jacob Menke"/><br /><sub><b>Jacob Menke</b></sub></a><br /><a href="#infra-MenkeTechnologies" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/md-command-line/gh_reveal/commits?author=MenkeTechnologies" title="Code">💻</a></td>
  </tr>
</table>

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
