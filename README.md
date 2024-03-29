# update code owners action

[![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/Onemind-Services-LLC/update-codeowners/build/master?style=for-the-badge)](https://github.com/Onemind-Services-LLC/update-codeowners/actions)
[![Renovate Status](https://img.shields.io/badge/renovate-enabled-green?style=for-the-badge&logo=renovatebot&color=1a1f6c)](https://app.renovatebot.com/dashboard#github/Onemind-Services-LLC/update-codeowners)
[![CodeFactor](https://www.codefactor.io/repository/github/Onemind-Services-LLC/update-codeowners/badge?style=for-the-badge)](https://www.codefactor.io/repository/github/Onemind-Services-LLC/update-codeowners)
[![GitHub License](https://img.shields.io/github/license/Onemind-Services-LLC/update-codeowners.svg?style=for-the-badge)](https://github.com/Onemind-Services-LLC/update-codeowners/blob/master/LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/Onemind-Services-LLC/update-codeowners.svg?style=for-the-badge&color=9cf)](https://github.com/Onemind-Services-LLC/update-codeowners/commits/master)

This is a [GitHub Action](https://github.com/features/actions) that uses [git-fame](https://pypi.org/project/git-fame) to generate and update GitHub's CODEOWNERS file based on the git fame of individual files.

## What does it do?

GitHub's [CODEOWNERS](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/about-code-owners)
feature doesn't provide any method for keeping the code owners list updated automatically.
This action solves this by determining code owners based on the git fame of each file.
Authors don't have to be asked for their addition based on subjective criteria anymore.

<!--- BEGIN_ACTION_DOCS --->
## Inputs

### distribution
![Required](https://img.shields.io/badge/Required-no-inactive?style=flat-square)
![Default](https://img.shields.io/badge/Default-25-f6e112?style=flat-square)

The distribution input defines the minimum percentage of code lines that are required for a contributor to being
considered a code owner.
Set it to any integer without the percent character to override the default.


### granular
![Required](https://img.shields.io/badge/Required-no-inactive?style=flat-square)
![Default](https://img.shields.io/badge/Default-''-inactive?style=flat-square)

By default, this action checks all files in the root, but groups recursive files into their parent directories.
Set this input to any non-zero value (e.g. `true`) to enable full coverage of all recursive files.


### path
![Required](https://img.shields.io/badge/Required-no-inactive?style=flat-square)
![Default](https://img.shields.io/badge/Default-.github/CODEOWNERS-7f9004?style=flat-square)

This defines the path to the CODEOWNERS file.
The default uses the path to the `.github` directory.


### token
![Required](https://img.shields.io/badge/Required-no-inactive?style=flat-square)
![Default](https://img.shields.io/badge/Default-${{_github.token_}}-ef2366?style=flat-square)

A GitHub token has to be set if `inputs.username` is enabled.
This is necessary because the GitHub API has a rate limit.
The default token has sufficient permissions for the API.


### username
![Required](https://img.shields.io/badge/Required-no-inactive?style=flat-square)
![Default](https://img.shields.io/badge/Default-''-inactive?style=flat-square)

By default, this action uses the email addresses of users.
Set this input to any non-zero value (e.g. `true`) to derive the GitHub usernames and use them instead.


<!--- END_ACTION_DOCS --->

## Example

This is a typical example for a pull request workflow.
It should suffice to trigger it on few event types of pull request events only.
That also gives the author the possibility to remove themselves from the owners list optionally.
Make sure to use `fetch-depth: 0` because otherwise, no git fame will be detected due to the lack of history.

<!-- add-file: ./.github/workflows/example.yml -->
``` yml markdown-add-files
name: codeowners

on:
  pull_request_target:
    paths-ignore:
      - '**/CODEOWNERS'
      - 'LICENSE'
    branches:
      - master
    types:
      - ready_for_review
      - review_request_removed
      - reopened
      - labeled

jobs:
  update:
    runs-on: ubuntu-latest
    # only apply on unmerged pull requests
    if: github.event.pull_request.merged_by == ''
    steps:
    - name: checkout code
      uses: actions/checkout@v2.3.4
      with:
        # this only makes sure that forks are built as well
        repository: ${{ github.event.pull_request.head.repo.full_name }}
        ref: ${{ github.head_ref }}
        # the fetch depth 0 (=all) is important
        fetch-depth: 0
        # the token is necessary for checks to rerun after auto commit
        token: ${{ secrets.PAT }}
    - name: update code owners
      uses: Onemind-Services-LLC/update-codeowners@v0.4.0
      with:
        distribution: 25
        username: true
    - uses: mszostok/codeowners-validator@v0.5.1
      id: validation
      if: ${{ steps.committed.outputs.changes_detected == 'true' }}
      with:
        checks: files,owners,duppatterns
        # the token is required only if the `owners` check is enabled
        github_access_token: ${{ secrets.PAT }}
    - name: commit changed files
      id: committed
      if: ${{ steps.committed.outputs.changes_detected == 'true' }}
      uses: stefanzweifel/git-auto-commit-action@v4.7.2
      with:
        commit_message: 'chore(meta): update code owners'
        file_pattern: .github/CODEOWNERS
    - uses: christianvuerings/add-labels@v1.1
      if: ${{ steps.committed.outputs.changes_detected == 'true' }}
      with:
        labels: owned
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```
