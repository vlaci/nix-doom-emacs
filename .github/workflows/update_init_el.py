#!/usr/bin/env python3
import sys
from difflib import unified_diff

from os import environ as env
from typing import cast
from github import Github
from github.ContentFile import ContentFile
from github.GithubException import GithubException
from github.Repository import Repository

API_TOKEN = env["GITHUB_API_TOKEN"]
REPOSITORY = env["GITHUB_REPOSITORY"]
BASE_BRANCH = env.get("GITHUB_BASE_BRANCH", "master")
DRY_RUN = bool(env.get("GITHUB_DRY_RUN", False))

INIT_EL = "test/doom.d/init.el"
UPSTREAM_INIT_EL = "init.example.el"
DOOM_UPSTREAM = "hlissner/doom-emacs"
UPSTREAM_BRANCH = "develop"


def create_pr(
    repo: Repository,
    pr_branch_name: str,
    head: str,
    file: ContentFile,
    updated_content: str,
    pr_title: str,
    pr_body: str,
):
    try:
        repo.get_branch(pr_branch_name)
        print(f"Branch '{pr_branch_name}' already exist. Skipping update.")
        return
    except GithubException as ex:
        if ex.status != 404:
            raise

    pr_branch = repo.create_git_ref(pr_branch_name, head)
    repo.update_file(
        file.path,
        f"{pr_title}\n\n{pr_body}",
        updated_content,
        file.sha,
        branch=pr_branch_name,
    )
    repo.create_pull(title=pr_title, body=pr_body, head=pr_branch.ref, base=BASE_BRANCH)


def main():
    if API_TOKEN:
        github = Github(API_TOKEN)
    else:
        print("GITHUB_API_TOKEN is required")
        sys.exit(1)

    repo = github.get_repo(REPOSITORY)
    head = repo.get_branch(BASE_BRANCH).commit.sha
    init_el = cast(ContentFile, repo.get_contents(INIT_EL, ref=BASE_BRANCH))
    doom_repo = github.get_repo(DOOM_UPSTREAM)
    upstream_init_el = cast(
        ContentFile, doom_repo.get_contents(UPSTREAM_INIT_EL, ref=UPSTREAM_BRANCH)
    )

    diff = "".join(
        unified_diff(
            init_el.decoded_content.decode().splitlines(keepends=True),
            upstream_init_el.decoded_content.decode().splitlines(keepends=True),
        )
    )

    if not diff:
        print(f"{INIT_EL} is up-to date")
        return

    print(f"{INIT_EL} updated.")
    print(diff)

    upstream_rev = doom_repo.get_branch(UPSTREAM_BRANCH).commit.sha
    title = f"{INIT_EL}: Updating from {DOOM_UPSTREAM} - {upstream_rev[:8]}"

    body = f"""\
### Changes for {INIT_EL}

```diff
{diff}
```
"""

    print(f"[{INIT_EL}] - Creating PR\nTitle: {title}\nBody:\n{body}")
    if DRY_RUN:
        print(f"DRY-RUN: NOT creating PR...")
        return

    pr_branch_name = f"refs/heads/update/init.el-{upstream_rev}"
    create_pr(
        repo,
        pr_branch_name,
        head,
        init_el,
        upstream_init_el.decoded_content.decode(),
        title,
        body,
    )


if __name__ == "__main__":
    main()
