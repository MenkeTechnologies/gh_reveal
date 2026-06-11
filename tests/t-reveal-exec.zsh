#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: gh_reveal — behavioral execution tests.
#####          Unlike the contract pins (which `cat`-grep the
#####          source), these RUN bin/reveal end-to-end with the
#####          OS `open` command stubbed onto PATH, capturing the
#####          exact URL the tool would launch. This exercises the
#####          real dispatch branches and the multi-stage
#####          remote-URL parsing pipeline (cut/sed/perl/awk), so a
#####          plausible-but-wrong refactor of any stage is caught
#####          by an asserted-exact URL rather than a substring pin.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    revealBin="$pluginDir/bin/reveal"

    tmp=$(mktemp -d)
    # Stub `open` + `xdg-open` so no browser launches. They append
    # their args to $capture so a test can assert the exact URL.
    stubDir="$tmp/stub"
    mkdir -p "$stubDir"
    capture="$tmp/capture.txt"
    : > "$capture"
    for stub in open xdg-open; do
        print -r -- '#!/usr/bin/env bash' >  "$stubDir/$stub"
        print -r -- 'echo "OPEN: $*" >> "$REVEAL_CAPTURE"' >> "$stubDir/$stub"
        chmod +x "$stubDir/$stub"
    done
    export REVEAL_CAPTURE="$capture"
    stubPath="$stubDir:$PATH"
}

@teardown {
    unset REVEAL_CAPTURE
    [[ -n "$tmp" && -d "$tmp" ]] && rm -rf "$tmp"
}

@test 'no-git-dir + no-args opens exactly <name>?tab=repositories (GITHUB_ACCOUNT wins, ? survives)' {
    # Bug class: URL-format regression + arg/name resolution.
    # Running in a NON-git dir with NO args must hit the
    # ___reveal_no_git_dir_no_args branch and open the user's repo
    # list. GITHUB_ACCOUNT must override git config user.name, and
    # the `?tab=repositories` query string must survive zsh globbing
    # (an unquoted `?` is a single-char glob metachar — if a refactor
    # drops `setopt localoptions shwordsplit`/quoting discipline the
    # `?` either errors with "no matches" or gets eaten).
    local nogit="$tmp/nogit"
    mkdir -p "$nogit"
    : > "$capture"
    ( builtin cd "$nogit" \
        && GITHUB_ACCOUNT='octocat' PATH="$stubPath" zsh -f "$revealBin" )
    local got
    got=$(cat "$capture")
    assert "$got" same_as 'OPEN: https://github.com/octocat?tab=repositories'
}

@test 'reveal <subdir> recurses into a git child and converts ssh remote to clean https URL' {
    # Bug class: the SSH->HTTPS transform pipeline + the recursion
    # branch. Parent dir is NOT a git repo; child `proj` IS, with an
    # ssh-form remote `git@github.com:octocat/Hello-World.git`. The
    # ___reveal_no_git_dir_yes_args branch must `cd proj` and
    # re-invoke reveal, whose pipeline (grep '@' | sed 's@:@/@g' |
    # cut -c 2- | awk | sed 's@.git$@@') must yield
    # `https://github.com/octocat/Hello-World` — colon->slash, leading
    # `@` stripped, trailing `.git` removed. A naive reimpl that skips
    # any stage produces a broken URL; this asserts the exact result.
    local proj="$tmp/rec/proj"
    mkdir -p "$proj"
    ( builtin cd "$proj" \
        && git init -q \
        && git remote add origin 'git@github.com:octocat/Hello-World.git' \
        && git config user.name tester )
    : > "$capture"
    ( builtin cd "$tmp/rec" \
        && PATH="$stubPath" zsh -f "$revealBin" proj )
    local got
    got=$(cat "$capture")
    assert "$got" same_as 'OPEN: https://github.com/octocat/Hello-World'
}

@test 'inside a git repo, https remote with :PORT/ has the port stripped before opening' {
    # Bug class: enterprise/CI remotes carry an explicit port
    # (https://host:443/...). The `perl -pe s@:\d{1,5}/@/@` stage must
    # strip `:443/` -> `/` so the browser URL is valid. If that perl
    # stage is dropped or its regex weakened, the opened URL keeps the
    # port and 404s. Asserts the exact port-free URL.
    local proj="$tmp/port/proj"
    mkdir -p "$proj"
    ( builtin cd "$proj" \
        && git init -q \
        && git remote add origin 'https://github.com:443/octocat/Hello-World.git' \
        && git config user.name tester )
    : > "$capture"
    ( builtin cd "$proj" \
        && PATH="$stubPath" zsh -f "$revealBin" )
    local got
    got=$(cat "$capture")
    assert "$got" same_as 'OPEN: https://github.com/octocat/Hello-World'
}
