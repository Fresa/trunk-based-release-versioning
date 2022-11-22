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
            echo "7c72ed06a8e21b2dc2c4a5d6b769ec5686170609"
            ;;
        "rev-parse e0b83ea6577431c046bcb35ba49f8630009cd83c^2")
            echo "7c72ed06a8e21b2dc2c4a5d6b769ec5686170609"
            ;;
        "log e0b83ea6577431c046bcb35ba49f8630009cd83c -1 --pretty=format:hash: %H%nmessage: | %n%w(0,1,1)%B%w(0,0,0)%n---")
            head -c -1 <<EOF
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
    Merge pull request #1 from foo/bar

    A message

---
EOF
            ;;
        "log b0b120b7d93b4d5acfb4b7f9f4e5beacb74e910e..7c72ed06a8e21b2dc2c4a5d6b769ec5686170609 --first-parent --pretty=format:hash: %H%nmessage: | %n%w(0,1,1)%B%w(0,0,0)%n---")
            cat << EOF
hash: e0b83ea6577431c046bcb35ba49f8630009cd83d
message: |
    a simple commit message


---
EOF
            ;;
        "log 7c72ed06a8e21b2dc2c4a5d6b769ec5686170609..master --first-parent --format=format:%D, %H --simplify-by-decoration --merges")
            ;;
        "log 7c72ed06a8e21b2dc2c4a5d6b769ec5686170609 --format=format:%D, %H --simplify-by-decoration")
            echo "master, 3b9fdcac8d57edb8785b8408eb4ffbe10bbef1d9"
            echo "origin/master, fcfd6fa79d2588039b54c776650a47a0ca8df718"
            echo "tag: sometag, eb89187b10b70f4f9532d94613cfff01bec3ac33"
            echo "tag: v1.2.1-branch2.1-1, fb89187b10b70f4f9532d94613cfff01bec3ac65"
            echo "tag: v1.2.0, tag: v1.1.9, tag: v1, b0b120b7d93b4d5acfb4b7f9f4e5beacb74e910e"
            echo "tag: v1.2.0-mybranch.1-2, a0b120b7d93b4d5acfb4b7f9f4e5beacb74e910f"
            echo "tag: v1.1.1, 4833df505a4f95e0213dd9f1ff636e1f36500cea"
            ;;
        "rev-list b0b120b7d93b4d5acfb4b7f9f4e5beacb74e910e..7c72ed06a8e21b2dc2c4a5d6b769ec5686170609 --first-parent --count")
            echo 2
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
    assertEquals "Incorrect version" "1.2.1" "$TBV_VERSION"
}

test_major_version() {
    assertEquals "Incorrect major version" "1" "$TBV_MAJOR_VERSION"
}

test_minor_version() {
    assertEquals "Incorrect minor version" "2" "$TBV_MINOR_VERSION"
}

test_patch_version() {
    assertEquals "Incorrect patch version" "1" "$TBV_PATCH_VERSION"
}

test_is_pre_release() {
    assertFalse "Should not be pre-release" $TBV_IS_PRERELEASE
}

test_last_release_ref() {
    assertEquals "Should have set last release ref" "b0b120b7d93b4d5acfb4b7f9f4e5beacb74e910e" "$TBV_LAST_RELEASE_REF"
}

test_last_version() {
    assertEquals "Should have set last version" "1.2.0" "$TBV_LAST_VERSION"
}

test_release_ref() {
    assertEquals "Should have set release ref" "e0b83ea6577431c046bcb35ba49f8630009cd83c" "$TBV_RELEASE_REF"
}

test_release_notes() {
    assertEquals "Should have generated commit logs for the release" \
"$(cat << EOF 
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
    Merge pull request #1 from foo/bar

    A message

---
hash: e0b83ea6577431c046bcb35ba49f8630009cd83d
message: |
    a simple commit message


---
EOF
)" \
"$(cat tbv_commit_logs.txt)" 
}

test_commit_count() {
    assertEquals "Should have calculated commit count" 3 "$TBV_COMMIT_COUNT"
}

test_commit_logs_path() {
    assertTrue "Should have written commit logs to file" '[ -r "$TBV_COMMIT_LOGS_PATH" ]'
}

# Remove all arguments this file was called with before calling shunit2 or it will throw
shift $#
. shunit2
