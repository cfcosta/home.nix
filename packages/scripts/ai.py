import os
import sys
from pathlib import Path
import click


def find_executables() -> list[str]:
    """Find all ai-* executables in PATH."""
    commands = []
    paths = os.environ.get("PATH", "").split(os.pathsep)
    
    for path in paths:
        if not path:
            continue
        path_dir = Path(path)
        if not path_dir.exists():
            continue
            
        for item in path_dir.iterdir():
            if item.name.startswith("ai-") and os.access(item, os.X_OK):
                name = item.name[3:]  # Remove 'ai-' prefix
                if name not in commands:  # Avoid duplicates from multiple PATH entries
                    commands.append(name)

    return sorted(commands)


@click.group(invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """AI command suite."""
    if ctx.invoked_subcommand is None:
        commands = find_executables()
        if not commands:
            click.echo("No AI commands found", err=True)
            sys.exit(1)

        # If no specific command given, show the list
        if len(sys.argv) == 1:
            click.echo("Available commands:")
            for cmd in commands:
                click.echo(f"  {cmd}")
            sys.exit(1)
        else:
            # Handle the command by calling run
            run.callback(sys.argv[1:])


@cli.command(context_settings={"ignore_unknown_options": True})
@click.argument("args", nargs=-1, type=click.UNPROCESSED)
def run(args):
    """Run an AI command."""
    if not args:
        click.echo("Error: Command name required", err=True)
        sys.exit(1)

    subcommand = args[0]
    # Search in PATH for the executable
    executable = None
    for path in os.environ.get("PATH", "").split(os.pathsep):
        if not path:
            continue
        candidate = Path(path) / f"ai-{subcommand}"
        if candidate.exists() and os.access(candidate, os.X_OK):
            executable = candidate
            break

    if executable:
        os.execv(executable, [str(executable)] + list(args[1:]))
    else:
        click.echo(f"Error: No command found for '{subcommand}'", err=True)
        sys.exit(1)


def main():
    """Main entry point."""
    cli()


if __name__ == "__main__":
    main()
