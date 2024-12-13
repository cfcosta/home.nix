#!/usr/bin/env python3

import json
from typing import Iterator

import click
import requests
from pydantic import BaseModel


def fetch_items(owner: str, repo: str, kind: str) -> Iterator[dict]:
    """Fetch all items (issues or PRs) from a GitHub repository."""
    base_url = f"https://api.github.com/repos/{owner}/{repo}/{kind}"
    page = 1

    while True:
        params = {
            "state": "all",
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


@click.group()
def cli():
    """Download issues or pull requests from a GitHub repository."""
    pass


@cli.command()
@click.argument("repository", type=str)
def issues(repository: str):
    """Download all issues from a GitHub repository.

    REPOSITORY should be in the format: owner/repo
    Example: octocat/Hello-World
    """
    repo = validate_repo(repository)

    for issue in fetch_items(repo.owner, repo.repo, "issues"):
        try:
            click.echo(json.dumps(issue, indent=2))
            click.echo("-" * 80)  # Separator between issues
        except requests.exceptions.RequestException as e:
            click.echo(f"Error fetching issues: {e}", err=True)
        except Exception as e:
            click.echo(f"Unexpected error: {e}", err=True)


@cli.command()
@click.argument("repository", type=str)
def pulls(repository: str):
    """Download all pull requests from a GitHub repository.

    REPOSITORY should be in the format: owner/repo
    Example: octocat/Hello-World
    """
    repo = validate_repo(repository)

    for issue in fetch_items(repo.owner, repo.repo, "pulls"):
        try:
            click.echo(json.dumps(issue, indent=2))
            click.echo("-" * 80)  # Separator between issues
        except requests.exceptions.RequestException as e:
            click.echo(f"Error fetching issues: {e}", err=True)
        except Exception as e:
            click.echo(f"Unexpected error: {e}", err=True)


if __name__ == "__main__":
    cli()
