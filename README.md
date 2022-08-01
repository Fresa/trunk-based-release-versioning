# Trunk-Based Release Versioning
Calculates version and release metadata based on the [Trunk-Based Development](https://trunkbaseddevelopment.com/) branching model.

[![Continuous Delivery](https://github.com/Fresa/trunk-based-release-versioning/actions/workflows/cd.yml/badge.svg)](https://github.com/Fresa/trunk-based-release-versioning/actions/workflows/cd.yml)

# Installation

```yaml
name: Continuous Delivery
on:
  push:
    branches: 
      - '**'

jobs:
  cd:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        # Fetches entire history, so we can analyze commits to determine next version and release
        fetch-depth: 0
    - name: Determine Release Info
      id: release
      uses: Fresa/trunk-based-release-versioning@main
    - run: echo "Release version: ${{ steps.release.outputs.version }}"
```
It's recommended to use the latest major version tag to automatically track the latest minor and patch version. See [tags](https://github.com/Fresa/trunk-based-release-versioning/tags).

See the [Continuous Delivery](.github/workflows/cd.yml) workflow for a more extensive example how this action can be used for creating releases.

## Not Using Github Actions?
It's just a single bash script file that can be referenced and downloaded in a similar way as in a Github Action workflow. Make sure to replace/set $VERSION to a valid git reference. The script exports the output to the executing shell session.
```sh
. <(curl -s https://raw.githubusercontent.com/Fresa/trunk-based-release-versioning/$VERSION/src/calc_version.sh)
```

# Inputs / Outputs
See [actions.yml](action.yml)

# How Does It Work?
Previous releases are determined by analyzing git tags in [SemVer](https://semver.org/) format; [`^v[0-9]*\.[0-9]*\.[0-9]*$`](https://regex101.com/r/GdW99V/1), ex. `v1.2.3`, so always tag your full releases in this format.

The release version is calculated by looking for [Conventional Commits](https://www.conventionalcommits.org/). One of the SemVer version parts will be incremented per full release based on the commit messages where major takes precedence over minor and patch and minor takes precedence over patch. Patch is incremented by default if no other conventional commits are found.

Prereleases are any commits not reachable from the default branch. 

Determining releases work with both [Trunk-Based Development For Smaller Teams](https://trunkbaseddevelopment.com/#trunk-based-development-for-smaller-teams) and [Scaled Trunk-Based Development](https://trunkbaseddevelopment.com/#scaled-trunk-based-development).

## Trunk-Based Development For Smaller Teams
A release includes all commits explicitly commited on the default branch since last release.

## Scaled Trunk-Based Development
The following two scenarios apply.
### Committing on a Development Branch
The release includes all commits on the branch since last reachable release tag. Any commits merged into the branch are ignored. These releases are considered prereleases.

It's recommended to tag these releases as prereleases according to the SemVer standard, but anything that does not match the version regex described earlier will do, including not tagging the commits at all.
### Merge Commit on the Default Branch
Handled the same way as if it were a commit on a development branch, except it is considered a full release.

It's recommended to tag these releases according to the full release version regex described earlier.

# Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

# License
[MIT](LICENSE)
