#!/usr/bin/env python3
import json
import sys
import re
from tempfile import TemporaryDirectory
from subprocess import check_call
from difflib import unified_diff

from os import environ as env, path
from typing import NamedTuple, cast
from github import Github
from github.ContentFile import ContentFile
from github.GitCommit import GitCommit
from github.GithubException import GithubException
from github.Repository import Repository

API_TOKEN = env["GITHUB_API_TOKEN"]
REPOSITORY = env["GITHUB_REPOSITORY"]
BASE_BRANCH = env.get("GITHUB_BASE_BRANCH", "master")
DRY_RUN = bool(env.get("GITHUB_DRY_RUN", False))

LOCK = "flake.lock"
FLAKE = "flake.nix"


class Input(NamedTuple):
    repo: str
    branch: str
    rev: str


class FlakeLock:
    def __init__(self, github: Github, lock_contents) -> None:
        self._github = github
        self._lock = json.loads(lock_contents)

    @property
    def inputs(self):
        return self._lock["nodes"]["root"]["inputs"]

    def get_input(self, flake_input):
        n = self._lock["nodes"][flake_input]
        repo_id = f"{n['locked']['owner']}/{n['locked']['repo']}"
        branch = n["original"].get("ref")
        if not branch:
            repo = self._github.get_repo(repo_id)
            branch = repo.default_branch
        return Input(repo_id, branch, n["locked"]["rev"])


def nix_flake_update(repo, flake_input):
    check_call(["nix", "flake", "update", "--update-input", flake_input], cwd=repo)


def format_change(change: GitCommit, repo):
    sha = change.sha[:8]
    url = change.html_url
    msg = re.sub(
        r"#(?P<id>\d+)",
        f"[{repo}\u2060#\\g<id>](http://r.duckduckgo.com/l/?uddg=https://github.com/{repo}/issues/\\g<id>)",
        change.message.splitlines()[0],
    )
    return f"- [{sha}]({url}) {msg}"


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
    flake_contents = cast(ContentFile, repo.get_contents(FLAKE, ref=BASE_BRANCH))
    lock_contents = cast(ContentFile, repo.get_contents(LOCK, ref=BASE_BRANCH))
    lock_lines = lock_contents.decoded_content.decode().splitlines(keepends=True)

    lock = FlakeLock(github, lock_contents.decoded_content)

    for flake_input in lock.inputs:
        with TemporaryDirectory(prefix="nix-flake-update.") as root:
            with open(path.join(root, LOCK), "wb") as f:
                f.write(lock_contents.decoded_content)
            with open(path.join(root, FLAKE), "wb") as f:
                f.write(flake_contents.decoded_content)

            print(f"[{flake_input}] Checking for updates")
            nix_flake_update(root, flake_input)

            with open(path.join(root, LOCK), "r") as f:
                updated_lock_lines = f.readlines()

            diff = list(unified_diff(lock_lines, updated_lock_lines))

            if not diff:
                print(f"[{flake_input}] No update available")
                continue

            print(f"[{flake_input}] Updated")

            updated_lock_contents = "".join(updated_lock_lines)
            for l in diff:
                print(l, end="")

            old = lock.get_input(flake_input)
            new = FlakeLock(github, updated_lock_contents).get_input(flake_input)

            title = f"flake.lock: Updating '{flake_input} ({old.repo})' - {old.rev[:8]} -> {new.rev[:8]}"

            dep_repo = github.get_repo(new.repo)
            changes = dep_repo.compare(old.rev, new.rev)
            commit_messages = "\n".join(
                format_change(c.commit, new.repo)
                for c in changes.commits
                if len(c.parents) == 1
            )
            body = f"""\
### Changes for {flake_input}

On branch: {new.branch}
Commits: {changes.html_url}

{commit_messages}
"""

            print(f"[{flake_input}] - Creating PR\nTitle: {title}\nBody:\n{body}")
            if DRY_RUN:
                print(f"DRY-RUN: NOT creating PR...")
                continue

            pr_branch_name = f"refs/heads/update/{flake_input}-{new.rev}"
            create_pr(
                repo,
                pr_branch_name,
                head,
                lock_contents,
                updated_lock_contents,
                title,
                body,
            )


if __name__ == "__main__":
    main()
