#!/usr/bin/env python

import json
import re
import subprocess
from typing import Iterator

import click
import requests
from pydantic import BaseModel
from rich.console import Console
from rich.syntax import Syntax

console = Console()


class Owner(BaseModel):
    login: str
    id: int
    url: str


class Repo(BaseModel):
    id: int
    name: str
    full_name: str
    owner: Owner
    private: bool
    default_branch: str


class Branch(BaseModel):
    ref: str
    sha: str
    label: str
    repo: Repo


class PullRequest(BaseModel):
    number: int
    title: str
    body: str | None  # PR description can be None
    base: Branch
    head: Branch
    user: Owner  # PR author


def fetch_prs(owner: str, repo: str) -> Iterator[dict]:
    """Fetch all items (issues or PRs) from a GitHub repository."""
    base_url = f"https://api.github.com/repos/{owner}/{repo}/pulls"
    page = 1

    while True:
        params = {
            "state": "open",  # Only fetch open items
            "per_page": 100,
            "page": page,
        }

        headers = {"Accept": "application/vnd.github.v3+json"}

        response = requests.get(base_url, params=params, headers=headers)
        response.raise_for_status()

        items = response.json()
        if not items:  # No more items to fetch
            break

        for item in items:
            yield item

        page += 1


class Repository(BaseModel):
    owner: str
    repo: str


def validate_repo(repository: str) -> Repository:
    """Validate repository format and return a Repository object."""
    try:
        owner, repo = repository.split("/")
        return Repository(owner=owner, repo=repo)
    except ValueError:
        raise click.BadParameter("Repository must be in format 'owner/repo'")


class Remote(BaseModel):
    name: str
    owner: str
    repo: str


def github_remotes() -> list[Remote]:
    # Run jj command and capture output
    try:
        output = subprocess.check_output(
            ["jj", "git", "remote", "list", "--no-pager", "--color=never"],
            text=True,
        )
    except subprocess.CalledProcessError:
        return []

    remotes = []
    github_pattern = re.compile(
        r"^(\w+)\s+(?:git@github.com:|https://github.com/)([^/]+)/(.+?)(?:\.git)?$"
    )

    for line in output.strip().split("\n"):
        if match := github_pattern.match(line.strip()):
            name, owner, repo = match.groups()
            remotes.append(Remote(name=name, owner=owner, repo=repo))

    return remotes


@click.group()
def cli():
    """Download pull requests from a GitHub repository."""
    pass


def _print_raw(pr: PullRequest) -> None:
    json_str = json.dumps(pr.model_dump(), indent=2)
    syntax = Syntax(json_str, "json", theme="monokai", word_wrap=True)
    console.print(syntax)


def add_and_update_remote(branch: Branch) -> None:
    """Add or update a git remote for the given branch's repository."""
    remote_name = branch.repo.owner.login
    remote_url = f"git@github.com:{branch.repo.full_name}.git"
    existing_remotes = github_remotes()

    try:
        matching_remote = next(
            (
                r
                for r in existing_remotes
                if r.owner == branch.repo.owner.login and r.repo == branch.repo.name
            ),
            None,
        )

        if not matching_remote:
            # Add new remote
            subprocess.run(
                ["jj", "git", "remote", "add", remote_name, remote_url],
                check=True,
            )
            console.print(f"[blue]Added new remote[/] [green]{remote_name}[/]")

    except subprocess.CalledProcessError as e:
        console.print(f"[red]Error managing remote {remote_name}: {e}[/]")


def _print(pr: PullRequest) -> None:
    console.print(f"[bold]:: Importing pull request[/] [blue]#{pr.number}[/]")
    console.print()

    console.print(f"[magenta]{pr.title}[/]")
    console.print(f"[blue]@{pr.user.login}[/]")
    console.print(
        f"[red]{pr.head.repo.full_name}:{pr.head.ref}[/] -> [green]{pr.base.repo.full_name}:{pr.base.ref}[/]"
    )

    if pr.body:
        console.print()
        console.print(pr.body)

    console.print()


def get_default_repository() -> Repository:
    """Get the repository info from the current jj repo's remotes."""
    remotes = github_remotes()
    if not remotes:
        raise click.UsageError("No GitHub remotes found in the current repository")

    # First try to find 'origin' remote
    origin = next((r for r in remotes if r.name == "origin"), None)
    if origin:
        return Repository(owner=origin.owner, repo=origin.repo)

    # If no origin, use the first GitHub remote
    remote = remotes[0]
    return Repository(owner=remote.owner, repo=remote.repo)


@cli.command()
@click.option(
    "--repository",
    type=str,
    help="Override repository (format: owner/repo). Default: derived from jj remotes",
)
@click.option(
    "--show-raw", is_flag=True, help="Show raw JSON output with syntax highlighting"
)
@click.option("--sync", is_flag=True, help="Sync jujutsu remotes with github")
def pulls(repository: str | None = None, show_raw: bool = False, sync: bool = False):
    """Download all pull requests from the current repository.

    If --repository is not provided, uses the GitHub remote from current jj repository.
    Prefers 'origin' remote if available.
    """
    if repository:
        repo = validate_repo(repository)
    else:
        try:
            repo = get_default_repository()
            console.print(
                f"[blue]Using repository:[/] [green]{repo.owner}/{repo.repo}[/]"
            )
        except click.UsageError as e:
            console.print(f"[red]Error:[/] {str(e)}")
            console.print(
                "[yellow]Tip:[/] Provide --repository owner/repo or add a GitHub remote"
            )
            return

    for item in fetch_prs(repo.owner, repo.repo):
        try:
            pr = PullRequest.model_validate(item)

            if show_raw:
                _print_raw(pr)
            else:
                _print(pr)

            if sync:
                add_and_update_remote(pr.base)
                add_and_update_remote(pr.head)
        except Exception as e:
            console.print(f"[red]Error fetching PRs: {e}[/]")


if __name__ == "__main__":
    cli()
