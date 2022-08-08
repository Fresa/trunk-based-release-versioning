#!/bin/bash
next_version() {
  last_version=$1
  if [[ -z $last_version ]]; then
    last_version=0.0.0
  fi
  version_components=(${last_version//./ })
  commit_messages=$(cat tbv_commit_logs.txt)

  # Conventional Commits https://www.conventionalcommits.org/en/v1.0.0/
  # Major version
  # https://regex101.com/r/Ms7Vx6/3
  if [[ $commit_messages =~ (build|chore|ci|doc|feat|fix|perf|refactor|revert|style|test)(\([a-z]+\))?(!:[[:space:]].+|:[[:space:]](.+$'\n\n')+([[:space:]]+)?BREAKING CHANGE:[[:space:]].+) ]]; then
      version_components[0]=$((version_components[0]+1))
      version_components[1]=0
      version_components[2]=0
  # Minor version
  # https://regex101.com/r/Oqhi2m/4
  elif [[ $commit_messages =~ feat(\([a-z]+\))?:[[:space:]](.+$'\n\n')+ ]]; then
    version_components[1]=$((version_components[1]+1))
    version_components[2]=0
  # Patch
  else
    version_components[2]=$((version_components[2]+1))
  fi
  
  printf -v new_version "%s." "${version_components[@]}"
  echo ${new_version%.}
}

# Expects git log format "%D, %H"
get_previous_version_and_release_ref() {
  if test -t 0; then
    echo "No stdin detected"
    exit 1
  fi
  cat < /dev/stdin | \
    # Split all tags to separate lines
    awk -F ", " '{for (i=1;i<NF;i++) {print $i" "$NF}}' | \
    # Remove tag prefix
    sed 's/^tag: v//' | \
    # Remove tags that are not in SemVer format
    { grep '^[0-9]*\.[0-9]*\.[0-9]*[[:space:]]' || test $? = 1; } | \
    head -1 
}

default_branch=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
echo "default branch: $default_branch"
current_branch=$(git symbolic-ref HEAD | sed 's/refs[/]heads[/]//')
echo "current branch: $current_branch"
log_format="hash: %H%nmessage: | %n %s%n%n %b%n---"
release_ref=$(git rev-parse HEAD)
echo "release reference: $release_ref"
rm -f tbv_commit_logs.txt
commit_count=0

if [ "$current_branch" == "$default_branch" ]; then
  is_prerelease=false
  # Is this release a merge commit?
  if [ $(git rev-parse --verify $release_ref^2 2> /dev/null) ]; then
    to_ref=$(git rev-parse $release_ref^2)
    git log $release_ref -1 --pretty=format:"$log_format" >> tbv_commit_logs.txt
    echo >> tbv_commit_logs.txt
    commit_count=1
    echo "Release ref is a merge commit with child commit $to_ref"
  else
    to_ref="$release_ref"
    echo "$release_ref is not a merge commit using current branch commit tree to find last release"
  fi
else
  is_prerelease=true
  # Track the default branch if it is not already tracked
  if [[ -z $(git branch --list $default_branch) ]]; then
    git branch -t $default_branch origin/$default_branch
  fi

  to_ref="$release_ref"
fi

# Find any release on the target branch caused by previous merges from current branch
last_version_and_release_ref=$(git log $to_ref..$default_branch --first-parent --format=format:"%D, %H" --simplify-by-decoration --merges | \
  get_previous_version_and_release_ref)
# No release on target branch found from this branch? Look for last release from current commit
if [[ -z $last_version_and_release_ref ]]; then
  echo "No release found on target '$default_branch' caused by previous merge"
  # This might go beyond the 'life span' of the current branch as it might have been created from a commit that never ended up being a release
  last_version_and_release_ref=$(git log $to_ref --format=format:"%D, %H" --simplify-by-decoration | \
    get_previous_version_and_release_ref)
  last_release_ref=$(echo "$last_version_and_release_ref" | awk '{print $2}')
  from_ref=$last_release_ref
else
  last_release_ref=$(echo "$last_version_and_release_ref" | awk '{print $2}')
  echo "Found $last_release_ref on target branch $default_branch which caused a previous release from this branch"
  # Find the second parent which will be the commit that was merged into the target branch
  from_ref=$(git rev-parse $last_release_ref^2)
fi

last_version=$(echo "$last_version_and_release_ref" | awk '{print $1}')
echo "last version: $last_version"
echo "last release ref: $last_release_ref"

[[ -z $from_ref ]] && \
  revision_range="$to_ref" || \
  revision_range="$from_ref..$to_ref"
git log $revision_range --first-parent --pretty=format:"$log_format" >> tbv_commit_logs.txt
commit_logs_path="$(realpath .)/tbv_commit_logs.txt"
echo "wrote commit logs to $commit_logs_path"
commit_count=$(($(git rev-list $revision_range --first-parent --count)+$commit_count))

echo "is pre-release: $is_prerelease"
version=$(next_version $last_version)
version_components=(${version//./ })
echo "next version: $version"
echo "commit count: $commit_count"

export TBV_IS_PRERELEASE=$is_prerelease
export TBV_LAST_RELEASE_REF=$last_release_ref
export TBV_LAST_VERSION=$last_version
export TBV_RELEASE_REF=$release_ref
export TBV_VERSION=$version
export TBV_MAJOR_VERSION=${version_components[0]}
export TBV_MINOR_VERSION=${version_components[1]}
export TBV_PATCH_VERSION=${version_components[2]}
export TBV_COMMIT_COUNT=$commit_count
export TBV_COMMIT_LOGS_PATH=$commit_logs_path
