# Returns 0 if version $a is strictly greater than version $b.
# Dotted numeric comparison; prerelease suffixes (e.g. -rc.1) are ignored.
function __release_npm_version_gt -a a b
    set -l ap (string split . (string replace -r -- '-.*$' '' $a))
    set -l bp (string split . (string replace -r -- '-.*$' '' $b))
    set -l n (count $ap)
    if test (count $bp) -gt $n
        set n (count $bp)
    end
    for i in (seq $n)
        set -l x 0
        set -l y 0
        if test $i -le (count $ap)
            set x $ap[$i]
        end
        if test $i -le (count $bp)
            set y $bp[$i]
        end
        if test $x -gt $y
            return 0
        else if test $x -lt $y
            return 1
        end
    end
    return 1
end

function release-npm -a bump_type -d "Bump version, update CHANGELOG, commit, and tag"
    # --- Preconditions: nothing is mutated before all of these pass ---

    if test -z "$bump_type"
        echo "Usage: release-npm <patch|minor|major>"
        return 1
    end

    switch $bump_type
        case patch minor major
            # ok
        case '*'
            echo "Error: unknown bump type '$bump_type' (expected patch, minor, or major)"
            return 1
    end

    if not git rev-parse -q --is-inside-work-tree >/dev/null 2>&1
        echo "Error: not inside a git repository."
        return 1
    end

    if not test -f package.json
        echo "Error: package.json not found in current directory."
        return 1
    end

    if not test -f CHANGELOG.md
        echo "Error: CHANGELOG.md not found in current directory."
        return 1
    end

    if not string match -q -r -- '## \[Unreleased\]' < CHANGELOG.md
        echo "Error: no '## [Unreleased]' section found in CHANGELOG.md."
        return 1
    end

    # Latest release tag (v-prefixed or not); empty if none exist yet
    set -l latest (git for-each-ref --count=1 --sort=-v:refname \
        --format='%(refname:strip=2)' 'refs/tags/v[0-9]*' 'refs/tags/[0-9]*')

    # --- Release ---

    # 1. Bump package.json but prevent npm from committing automatically
    # We use local variables (-l) so they don't pollute your shell environment
    set -l new_version (npm version $bump_type --no-git-tag-version)

    if test $status -ne 0
        echo "Error: npm version failed."
        return 1
    end

    # Strip the "v" prefix if npm outputs it (e.g., v1.0.1 -> 1.0.1)
    set -l clean_version (string replace -r '^v' '' $new_version)
    set -l current_date (date +%Y-%m-%d)

    # The new version must be strictly newer than the latest release tag
    if test -n "$latest"; and not __release_npm_version_gt $clean_version (string replace -r '^v' '' $latest)
        echo "Error: $new_version is not newer than the latest release tag ($latest)."
        for f in package.json package-lock.json
            test -f $f; and git checkout -- $f
        end
        return 1
    end

    # 2. Update the CHANGELOG with a new version section.
    # Pure fish string handling: no sed, so it behaves identically on
    # GNU (Ubuntu), BSD (macOS), and busybox (Termux) systems.
    # (string collect keeps the file as one string, preserving blank lines;
    #  without -a, string replace only touches the first match.)
    set -l changelog (string collect < CHANGELOG.md)
    string replace -r '## \[Unreleased\]' "## [Unreleased]

## [$clean_version] - $current_date" -- $changelog > CHANGELOG.md

    # 3. Bundle it all into the release commit and tag
    git add package.json CHANGELOG.md

    # Include package-lock.json if it exists
    if test -f package-lock.json
        git add package-lock.json
    end

    git commit -m "Release $clean_version"
    git tag "$new_version"

    echo "Successfully cut release $new_version"
end
