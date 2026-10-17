# Returns 0 if version $a is strictly greater than version $b, following semver
# precedence: core numbers first, then a release beats prereleases of the same
# core (2.0.0 > 2.0.0-rc.1), then prerelease identifiers are compared one by one
# (numeric numerically, alphanumeric lexicographically, numeric < alphanumeric;
# e.g. 2.0.0-alpha.3 > 2.0.0-alpha.2 > 2.0.0-alpha.1 > 2.0.0-alpha). Build
# metadata (+...) is ignored.
function __release_npm_version_gt -a a b
    # Strip build metadata
    set -l a (string replace -r -- '\+.*$' '' $a)
    set -l b (string replace -r -- '\+.*$' '' $b)

    # Split "X.Y.Z-prerelease" into core and prerelease
    set -l a_parts (string split -m 1 -- - $a)
    set -l b_parts (string split -m 1 -- - $b)
    set -l a_pre ''
    set -l b_pre ''
    if test (count $a_parts) -ge 2
        set a_pre $a_parts[2]
    end
    if test (count $b_parts) -ge 2
        set b_pre $b_parts[2]
    end

    # Compare major.minor.patch numerically
    set -l ap (string split . $a_parts[1])
    set -l bp (string split . $b_parts[1])
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

    # Cores are equal: a release beats any prerelease of the same core
    if test -z "$a_pre"; and test -z "$b_pre"
        return 1
    end
    if test -z "$a_pre"
        return 0
    end
    if test -z "$b_pre"
        return 1
    end

    # Both are prereleases: compare dot-separated identifiers
    set -l a_ids (string split . $a_pre)
    set -l b_ids (string split . $b_pre)
    set -l n (count $a_ids)
    if test (count $b_ids) -gt $n
        set n (count $b_ids)
    end
    for i in (seq $n)
        set -l x ''
        set -l y ''
        if test $i -le (count $a_ids)
            set x $a_ids[$i]
        end
        if test $i -le (count $b_ids)
            set y $b_ids[$i]
        end
        # Fewer identifiers lose once all shared ones are equal
        if test -z "$x"
            return 1
        end
        if test -z "$y"
            return 0
        end
        set -l x_num 0
        set -l y_num 0
        string match -qr '^[0-9]+$' -- $x; and set x_num 1
        string match -qr '^[0-9]+$' -- $y; and set y_num 1
        if test $x_num -eq 1; and test $y_num -eq 1
            if test $x -gt $y
                return 0
            else if test $x -lt $y
                return 1
            end
        else if test $x_num -ne $y_num
            # Numeric identifiers have lower precedence than alphanumeric
            if test $y_num -eq 1
                return 0
            end
            return 1
        else
            # Both alphanumeric: lexicographic byte order
            set -l first (printf '%s\n%s\n' $x $y | LC_ALL=C sort | head -n 1)
            if test "$first" != "$x"
                return 0
            else if test "$x" != "$y"
                return 1
            end
        end
    end
    return 1
end

function release-npm -a bump_type -d "Bump version (or set an explicit version), update CHANGELOG, commit, and tag"
    # --- Preconditions: nothing is mutated before all of these pass ---

    if test -z "$bump_type"
        echo "Usage: release-npm <patch|minor|major|X.Y.Z>"
        return 1
    end

    switch $bump_type
        case patch minor major
            # ok
        case '*'
            # Not a bump keyword; accept an explicit semver (e.g. 2.0.0, v2.0.0,
            # 3.0.0-rc.1). This regex is just friendly routing -- npm does the
            # authoritative validation. POSIX ERE: no \d, no (?:...).
            if not string match -q -r -- '^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$' $bump_type
                echo "Error: unknown bump type or version '$bump_type' (expected patch, minor, major, or a semver like 2.0.0)"
                return 1
            end
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

    # 1. Set the new version in package.json (keyword bump or explicit semver)
    # but prevent npm from committing automatically
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
