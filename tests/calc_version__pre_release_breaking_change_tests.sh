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
            echo "refs/heads/mybranch"
            ;;
        "rev-parse HEAD")
            echo "e0b83ea6577431c046bcb35ba49f8630009cd83c"
            ;;
        "log 7c72ed06a8e21b2dc2c4a5d6b769ec5686170609..e0b83ea6577431c046bcb35ba49f8630009cd83c --first-parent --pretty=format:hash: %H%nmessage: | %n%w(0,1,1)%B%w(0,0,0)%n---")
            cat << EOF
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
 feat(foo): a simple commit message
 
 a body
 
 BREAKING CHANGE: broke something

---
hash: f0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
 feat(bar fee): another simple commit message

---
EOF
            ;;
        "log e0b83ea6577431c046bcb35ba49f8630009cd83c..master --first-parent --format=format:%D, %H --simplify-by-decoration --merges")
            echo "master, 3b9fdcac8d57edb8785b8408eb4ffbe10bbef1d9"
            echo "origin/master, fcfd6fa79d2588039b54c776650a47a0ca8df718"
            ;;
        "log e0b83ea6577431c046bcb35ba49f8630009cd83c --format=format:%D, %H --simplify-by-decoration")
            echo "master, 3b9fdcac8d57edb8785b8408eb4ffbe10bbef1d9"
            echo "origin/master, fcfd6fa79d2588039b54c776650a47a0ca8df718"
            echo "tag: sometag, eb89187b10b70f4f9532d94613cfff01bec3ac33"
            echo "tag: v1.2.0, 7c72ed06a8e21b2dc2c4a5d6b769ec5686170609"
            echo "tag: v1.2.0-mybranch.1-2, a0b120b7d93b4d5acfb4b7f9f4e5beacb74e910f"
            echo "tag: v1.1.1, 4833df505a4f95e0213dd9f1ff636e1f36500cea"
            ;;
        "rev-list 7c72ed06a8e21b2dc2c4a5d6b769ec5686170609..e0b83ea6577431c046bcb35ba49f8630009cd83c --first-parent --count")
            echo 2
            ;;
        *)
            echo "Incorrect git command: $@"
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
    assertEquals "Incorrect version" "2.0.0" "$TBV_VERSION"
}

test_major_version() {
    assertEquals "Incorrect major version" "2" "$TBV_MAJOR_VERSION"
}

test_minor_version() {
    assertEquals "Incorrect minor version" "0" "$TBV_MINOR_VERSION"
}

test_patch_version() {
    assertEquals "Incorrect patch version" "0" "$TBV_PATCH_VERSION"
}

test_is_pre_release() {
    assertTrue "Should be pre-release" $TBV_IS_PRERELEASE
}

test_last_release_ref() {
    assertEquals "Should have set last release ref" "7c72ed06a8e21b2dc2c4a5d6b769ec5686170609" "$TBV_LAST_RELEASE_REF"
}

test_last_version() {
    assertEquals "Should have set last version" "1.2.0" "$TBV_LAST_VERSION"
}

test_release_ref() {
    assertEquals "Should have set release ref" "e0b83ea6577431c046bcb35ba49f8630009cd83c" "$TBV_RELEASE_REF"
}

test_release_notes() {
    assertEquals "Should have generated commit logs for the release" "$(cat tbv_commit_logs.txt)" \
"$(cat << EOF 
hash: e0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
 feat(foo): a simple commit message
 
 a body
 
 BREAKING CHANGE: broke something

---
hash: f0b83ea6577431c046bcb35ba49f8630009cd83c
message: |
 feat(bar fee): another simple commit message

---
EOF
)"
}

test_commit_count() {
    assertEquals "Should have calculated commit count" 2 "$TBV_COMMIT_COUNT"
}

# Remove all arguments this file was called with before calling shunit2 or it will throw
shift $#
. shunit2
