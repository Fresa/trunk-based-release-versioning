#!/bin/bash
script_path=$(dirname $(readlink -f $0))
echo "Using script path: $script_path"
calc_version_path="$(dirname $script_path)/src"
echo "Path: $calc_version_path"

git() {
    case "$@" in
        "remote show origin")
            echo "* remote origin"
            echo "Fetch URL: https://github.com/foo/bar.git"
            echo "Push  URL: https://github.com/foo/bar.git"
            echo "HEAD branch: master"
            ;;
        "symbolic-ref HEAD")
            echo "refs/heads/master"
            ;;
        "rev-parse HEAD")
            echo "e0b83ea6577431c046bcb35ba49f8630009cd83c"
            ;;
        "rev-parse --verify e0b83ea6577431c046bcb35ba49f8630009cd83c^2")
            ;;
        "log e0b83ea6577431c046bcb35ba49f8630009cd83c --first-parent --format=format:%D, %H --simplify-by-decoration")
            echo "master, 3b9fdcac8d57edb8785b8408eb4ffbe10bbef1d9"
            echo "origin/master, fcfd6fa79d2588039b54c776650a47a0ca8df718"
            ;;
        "rev-list --max-parents=0 master")
            echo "e0b83ea6577431c046bcb35ba49f8630009cd83c"
            ;;
        "log e0b83ea6577431c046bcb35ba49f8630009cd83c --first-parent --pretty=format:hash: %H%nmessage: | %n%w(0,1,1)%B%w(0,0,0)%n---")
            cat << EOF
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
    a simple commit message


---
EOF
            ;;
        "rev-list e0b83ea6577431c046bcb35ba49f8630009cd83c --first-parent --count")
            echo 1
            ;;
        *)
            echo; echo
            echo "Unexpected git command: git $@"
            exit 1
            ;;
    esac
}
export -f git

oneTimeSetUp() {
    trap "rm -f tbv_commit_logs.txt" EXIT
    . $calc_version_path/calc_version.sh
}

test_version() {
    assertEquals "Incorrect version" "0.0.1" "$TBV_VERSION"
}

test_major_version() {
    assertEquals "Incorrect major version" "0" "$TBV_MAJOR_VERSION"
}

test_minor_version() {
    assertEquals "Incorrect minor version" "0" "$TBV_MINOR_VERSION"
}

test_patch_version() {
    assertEquals "Incorrect patch version" "1" "$TBV_PATCH_VERSION"
}

test_is_pre_release() {
    assertFalse "Should not be pre-release" $TBV_IS_PRERELEASE
}

test_last_release_ref() {
    assertEquals "Should have no last release ref" "" "$TBV_LAST_RELEASE_REF"
}

test_last_version() {
    assertEquals "Should have no last version" "" "$TBV_LAST_VERSION"
}

test_release_ref() {
    assertEquals "Should have set release ref" "e0b83ea6577431c046bcb35ba49f8630009cd83c" "$TBV_RELEASE_REF"
}

test_release_notes() {
    assertEquals "Should have generated commit logs for the release" "$(cat tbv_commit_logs.txt)" \
"$(cat << EOF 
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
    a simple commit message


---
EOF
)"
}

test_commit_count() {
    assertEquals "Should have calculated commit count" 1 "$TBV_COMMIT_COUNT"
}

# Remove all arguments this file was called with before calling shunit2 or it will throw
shift $#
. shunit2
