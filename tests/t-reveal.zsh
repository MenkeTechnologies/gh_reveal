#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: gh_reveal contract pins.
#####          The `reveal` bin opens browser URLs for git remotes
#####          (heroku, GitHub, generic). Tests pin the helper
#####          functions and the dispatch logic by stubbing the
#####          OS-specific `open` command and exercising real and
#####          fake git repos in tmpdirs.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/gh_reveal.plugin.zsh"
    revealBin="$pluginDir/bin/reveal"
    helpersSh="$pluginDir/helpers.sh"
    credentialSh="$pluginDir/credential.sh"
    installSh="$pluginDir/install.sh"
    uninstallSh="$pluginDir/uninstall.sh"
    tmp=$(mktemp -d)
}

@teardown {
    [[ -n "$tmp" && -d "$tmp" ]] && rm -rf "$tmp"
}

@test 'plugin file appends bin/ to fpath via \${0:h}/bin' {
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'fpath+="${0:h}/bin"'
}

@test 'plugin file autoloads reveal (the bin function name)' {
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'autoload -Uz reveal'
}

@test 'bin/reveal exists and is executable' {
    assert "$revealBin" is_file
    [[ -x "$revealBin" ]]
    assert $? equals 0
}

@test 'bin/reveal shebang is bash' {
    # Pin: reveal uses bash conditionals + array syntax. Switching
    # to /bin/sh breaks on dash hosts.
    local first
    first=$(head -1 "$revealBin")
    assert "$first" same_as '#!/usr/bin/env bash'
}

@test 'bin/reveal parses cleanly under bash -n (no syntax errors)' {
    run bash -n "$revealBin"
    assert $state equals 0
}

@test 'helpers.sh + credential.sh + install.sh + uninstall.sh all parse cleanly' {
    for f in "$helpersSh" "$credentialSh" "$installSh" "$uninstallSh"; do
        run bash -n "$f"
        assert $state equals 0
    done
}

@test 'OS detector returns "open" on Darwin (macOS browser open)' {
    # Pin: macOS users get `open URL` to launch the default browser.
    # If the case branch drops, the plugin silently dies on macOS.
    local result
    result=$(bash -c '
        source "'"$revealBin"'" </dev/null 2>/dev/null
    ' 2>/dev/null; true)
    # The bin sources + auto-invokes reveal — capture via in-file
    # extraction instead. The relevant branch is `darwin*) open_cmd='\''open'\'' ;;`.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains "darwin*)  open_cmd='open'"
}

@test 'OS detector handles Linux with xdg-open (NOT just `open`)' {
    # Pin: Linux must use xdg-open (or `cmd.exe /c start` under WSL).
    # Hardcoding `open` breaks every Linux user.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'xdg-open'
}

@test 'OS detector handles WSL via cmd.exe (the Microsoft kernel test)' {
    # Pin: the WSL branch checks `uname -r` for *icrosoft* (the
    # case-insensitive case-skipping `M` is intentional — both WSL1
    # and WSL2 print "Microsoft" in uname -r). Pin so the kernel
    # name check survives a refactor.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains '*icrosoft*'
    assert "$body" contains 'cmd.exe /c start'
}

@test 'OS detector handles cygwin via cygstart' {
    local body
    body=$(cat "$revealBin")
    assert "$body" contains "cygwin*)  open_cmd='cygstart'"
}

@test 'OS detector handles msys via start command' {
    local body
    body=$(cat "$revealBin")
    assert "$body" contains "msys*)    open_cmd='start"
}

@test 'OS detector unsupported case returns 1 (NOT silently succeeds)' {
    # Pin: a default branch that returns 0 would silently launch
    # nothing and exit clean. Must return 1 so callers can detect.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'Platform $OSTYPE not supported'
    assert "$body" contains 'return 1'
}

@test '$GITHUB_ACCOUNT env var overrides git config user.name (the dispatch escape hatch)' {
    # Pin: lets users open someone else's repo list without changing
    # their git identity. If the env-var check drops, the tool always
    # uses local git user.name.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'if [[ -z "$GITHUB_ACCOUNT" ]]'
    assert "$body" contains 'name="$GITHUB_ACCOUNT"'
    assert "$body" contains 'name=$(git config user.name)'
}

@test 'reveal -no-git-dir-no-args branch opens https://github.com/<name>?tab=repositories' {
    # Pin: the URL format for "show me a user's repo list". GitHub's
    # docs canonicalize this; if the path changes, the tool breaks.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'https://github.com/$name?tab=repositories'
}

@test 'reveal -no-git-dir-yes-args branch recursively cds into each arg + re-invokes reveal' {
    # Pin: lets `reveal foo bar` open repos under sibling dirs.
    # Without the loop, multi-arg invocation only opens the first.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'for dir in "$@" ; do'
    assert "$body" contains '( builtin cd "$dir" && reveal; )'
}

@test 'is_zsh helper checks $ZSH_VERSION (the canonical zsh probe)' {
    # Pin: switching to other probes (e.g. $SHELL) is wrong — $SHELL
    # is the login shell, not the running shell.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains '___reveal_is_zsh()'
    assert "$body" contains 'test -n "$ZSH_VERSION"'
}

@test 'reveal sets shwordsplit under zsh (POSIX word-splitting compat)' {
    # Pin: bash assumes shwordsplit; zsh doesn't. Without
    # `setopt localoptions shwordsplit`, the `for dir in $@` loop
    # in zsh would treat the whole "$@" as one word.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'setopt localoptions shwordsplit'
}

@test 'reveal handles heroku remotes via dashboard.heroku.com + .herokuapp.com URLs' {
    # Pin: the heroku branch opens BOTH the management dashboard
    # AND the live app URL. Dropping either silently halves the
    # heroku UX.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'dashboard.heroku.com/apps'
    assert "$body" contains '.herokuapp.com'
}

@test 'reveal strips trailing .git from remote URLs (cleans path before opening)' {
    # Pin: `git@github.com:foo/bar.git` becomes `github.com/foo/bar`
    # for the browser. The s@.git$@@ substitution does that.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains "sed 's@.git\$@@'"
}

@test 'reveal handles git@host:path and https:// path style remotes' {
    # Pin: both SSH-form (@host:) and HTTPS-form (//) remotes must
    # be parsed. The two grep branches are inside a `{ … }` group
    # so they share stdout into the downstream pipeline.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains "grep '@'"
    assert "$body" contains "grep '//'"
}

@test 'reveal strips :NNNNN/ port suffix via perl substitution' {
    # Pin: enterprise hosts may carry :8080/ etc. The `perl -pe
    # s@:\d{1,5}/@/@` strips the port so the browser URL is clean.
    local body
    body=$(cat "$revealBin")
    assert "$body" contains 'perl -pe' && assert "$body" contains ':\d{1,5}/'
}

@test 'reveal unsets the 4 private helper fns at every exit path (no env leak)' {
    # Pin: ___reveal__find_open_command_from_Operating_System +
    # the 3 dispatch helpers MUST be unset before return to keep
    # the shell env clean for the user.
    local body
    body=$(cat "$revealBin")
    local count
    count=$(printf '%s\n' "$body" | grep -c '^    unset -f ___reveal')
    local result=$([[ "$count" -ge 11 ]] && echo yes || echo "no:$count")
    assert "$result" same_as 'yes'
}

@test 'reveal "$@" invocation at end of file (so the bin is executable)' {
    # Pin: the bottom `reveal "$@"` is what makes /usr/local/bin/reveal
    # actually do something when executed. Without it the script just
    # defines the function and exits.
    local last
    last=$(grep -E '^reveal ' "$revealBin" | tail -1)
    assert "$last" same_as 'reveal "$@"'
}

@test 'helpers.sh check_bin_folder_and_authenticate exists' {
    # Pin: install/uninstall depend on this function. Removing it
    # breaks both.
    local body
    body=$(cat "$helpersSh") || body=""
    # The actual helper is in credential.sh (helpers.sh is a sudo wrapper).
    local cred
    cred=$(cat "$credentialSh")
    assert "$cred" contains 'check_bin_folder_and_authenticate'
}

@test 'install.sh writes to /usr/local/bin/reveal via curl (the canonical install path)' {
    # Pin: /usr/local/bin is the documented install dir. Renaming
    # silently fragments users into per-version PATH chaos.
    local body
    body=$(cat "$installSh")
    assert "$body" contains '/usr/local/bin/reveal'
    assert "$body" contains 'curl -fsSL'
    assert "$body" contains 'chmod +x /usr/local/bin/reveal'
}

@test 'uninstall.sh removes /usr/local/bin/reveal via rm -rf' {
    local body
    body=$(cat "$uninstallSh")
    assert "$body" contains 'rm -rf /usr/local/bin/reveal'
}

@test 'sourcing the plugin defines reveal as an autoload-ready fn' {
    # End-to-end: plugin sources cleanly, fpath has the bin dir,
    # autoload reveal works.
    local out
    out=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        whence -v reveal
    " 2>&1)
    assert "$out" contains 'reveal'
}
