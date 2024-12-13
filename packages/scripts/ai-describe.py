#!/usr/bin/env python

"""Generate commit messages using LLM and describe JJ commits."""

import asyncio
import os
import string
import subprocess
import sys
from typing import Any, cast

import click
import litellm

REASON_PROMPT_TEMPLATE = string.Template("""
You are an expert software engineer analyzing the historical context of recent changes. Your task involves reviewing previous commits to build a clear picture of the development context that led to the current changes.

Your goal: Create a concise narrative of the development history that:
1. Establishes the historical context and evolution of the codebase
2. Identifies recurring themes or ongoing development efforts
3. Highlights relevant technical decisions made previously
4. Maps out dependencies and relationships between past changes
5. Provides background knowledge needed to understand current changes

Historical commits to analyze:
```
${CHANGES}
```

Provide a clear summary of this historical context, focusing on how past changes inform and relate to ongoing development. This context will help frame new changes within the broader development narrative.
""")

PROMPT_TEMPLATE = string.Template("""
You are an expert software engineer who creates precise, meaningful Git commit messages that serve as reliable documentation of changes.

**Historical Context and Related Changes**:
```
${CURRENT_SUMMARY}
```

**Instructions**:

1. **E-Prime Rules (MANDATORY)**:
   - Avoid ALL forms of the verb "to be" (is, are, was, were, be, been, being)
   - Replace "is/are" constructions with active verbs
   - Examples:
     * Instead of "This is a bug fix" → "This fixes a bug"
     * Instead of "API was updated" → "API now supports"
     * Instead of "Changes are needed" → "Changes improve"

2. **Commit Message (First Line)**:
   - Review the provided context and diff thoroughly.
   - Produce a single-line commit message of the form:
     ```
     <type>(<program>): <description>
     ```
     where:
     - `<type>` ∈ {`fix`, `feat`, `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`}
     - `<program>` identifies the primary component affected
     - `<description>` must:
       * Use imperative mood ("add" not "added")
       * Start with a specific, meaningful verb
       * Describe WHAT changed, not HOW it changed
       * Fit within 72 characters total
       * Avoid vague terms like "update", "fix", "improve"
       * Include key impact or scope (e.g., "udd retry logic to API calls")
   
2. **Explanation (Subsequent Lines)**:
   - After the commit message, add a blank line.
   - The explanation must include:
     * The primary motivation for the change
     * Technical context necessary for understanding
     * Impact on system behavior or performance
     * Any important limitations or constraints considered
     * Relationship to other recent changes if relevant
   - Format requirements:
     * Use clear, factual language
     * Avoid subjective descriptions or opinions
     * STRICTLY use E-Prime:
       - NO forms of "to be" (is/are/was/were/be/been/being)
       - Use active verbs instead of state descriptions
       - Convert "X is Y" to "X does/has/provides Y"
     * Structure in logical paragraphs
     * Focus on WHY over HOW
     * Include technical details only when they affect future maintenance
   
**Output Format**:
```markdown
<type>(<program>): <one-line-imperative-commit-message-under-72-chars>

<detailed-explanation-here>
```

**Example**:
```markdown
fix(ingest): remove deprecated function call

This change replaces the old `oldMethod()` with `newMethod()` to align with...
```

**Final Instructions**:  
Print with the commit message, the blank line, and the explanation. Do not include extra commentary or formatting beyond the specified output format.
""")


def run_command(cmd: list[str]) -> str:
    """Run a shell command and return its output."""
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()


async def get_context(
    revision: str = "@",
    context: str = "main..@-",
    use_reason: bool = False,
    temperature: float = 1.0,
    max_tokens: int = 1024,
) -> dict:
    """Gather all the context needed for the commit message."""
    current_summary = run_command(
        ["jj", "show", "-r", revision, "--summary", "--color-words"]
    )

    if use_reason:
        changes = run_command(
            [
                "jj",
                "log",
                "--git",
                "--no-pager",
                "--no-graph",
                "--ignore-all-space",
                "-r",
                context,
            ]
        )
        repository_context = await generate_reason(
            changes, temperature=temperature, max_tokens=max_tokens
        )
    else:
        repository_context = run_command(
            [
                "jj",
                "log",
                "-r",
                context,
                "--summary",
                "--ignore-all-space",
                "--ignore-working-copy",
            ]
        )

    return {
        "CURRENT_SUMMARY": current_summary,
        "REPOSITORY_CONTEXT": repository_context,
    }


async def generate_reason(
    changes: str,
    temperature: float = 1.0,
    max_tokens: int = 1024,
) -> str:
    """Generate a reasoned analysis of the changes using LLM."""
    prompt = REASON_PROMPT_TEMPLATE.substitute({"CHANGES": changes})

    full_message = []
    model = os.getenv(
        "REASON_AI_MODEL", os.getenv("AI_MODEL", "cerebras/llama-3.3-70b")
    )
    print(f"Generating change analysis using {model}:", file=sys.stderr)

    async for chunk in await litellm.acompletion(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=temperature,
        max_tokens=max_tokens,
        stream=True,
    ):
        content = cast(Any, chunk).choices[0].delta.content
        if content:
            print(content, end="", file=sys.stderr, flush=True)
            full_message.append(content)

    print("\n", file=sys.stderr)
    return "".join(full_message).strip()


async def generate_commit_message(
    context: dict,
    temperature: float = 1.0,
    max_tokens: int = 1024,
) -> str:
    """Generate a commit message using LLM."""
    prompt = PROMPT_TEMPLATE.substitute(context)

    full_message = []
    model = os.getenv("AI_MODEL", "cerebras/llama-3.3-70b")
    print(f"Generating commit message using {model}:", file=sys.stderr)

    async for chunk in await litellm.acompletion(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=temperature,
        max_tokens=max_tokens,
        stream=True,
    ):
        content = cast(Any, chunk).choices[0].delta.content
        if content:
            print(content, end="", file=sys.stderr, flush=True)
            full_message.append(content)

    print("\n", file=sys.stderr)

    message = "".join(full_message).strip()
    if not message:
        raise ValueError("Got no response")

    # Extract content from markdown code block if present

    if message.startswith("```") and message.endswith("```"):
        # Split on ``` and take the middle part
        parts = message.split("```")
        if len(parts) >= 3:
            # If the first line after ``` is a language identifier, skip it
            content = parts[1].strip()
            if "\n" in content:
                first_line, rest = content.split("\n", 1)
                if first_line.lower() in ["markdown"]:
                    content = rest
            message = content.strip()

    return message


@click.command()
@click.option(
    "-r",
    "--revision",
    default="@",
    help="Revision to describe (default: @)",
)
@click.option(
    "--context",
    default="main..@-",
    help="Revision range for context (default: main..@-)",
)
@click.option(
    "--model",
    envvar="AI_MODEL",
    default="cerebras/llama-3.3-70b",
    help="LLM model to use for generation",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Print the commit message without applying it",
)
@click.option(
    "--temperature",
    type=float,
    default=1.0,
    help="Temperature for LLM generation (0.0-2.0)",
)
@click.option(
    "--max-tokens",
    type=int,
    default=1024,
    help="Maximum tokens in the generated response",
)
@click.option(
    "--reason/--no-reason",
    default=False,
    help="Use AI reasoning for repository context analysis",
)
@click.option(
    "--reason-model",
    envvar="REASON_AI_MODEL",
    help="LLM model to use for reasoning (defaults to AI_MODEL)",
)
def main(
    revision: str = "@",
    context: str = "main..@-",
    model: str = "cerebras/llama-3.3-70b",
    reason_model: str | None = None,
    reason: bool = False,
    dry_run: bool = False,
    temperature: float = 1.0,
    max_tokens: int = 1024,
):
    async def run(
        revision: str,
        context: str,
        model: str,
        dry_run: bool,
        temperature: float,
        max_tokens: int,
    ):
        """Generate and apply AI-powered commit messages for JJ commits."""
        try:
            # Override the model in the generate function
            os.environ["AI_MODEL"] = model

            if reason_model:
                os.environ["REASON_AI_MODEL"] = reason_model

            context_data = await get_context(
                revision=revision,
                context=context,
                use_reason=reason,
                temperature=temperature,
                max_tokens=max_tokens,
            )

            commit_msg = await generate_commit_message(
                context_data,
                temperature=temperature,
                max_tokens=max_tokens,
            )

            if dry_run:
                print(commit_msg)
            else:
                # Apply the commit message using jj describe
                subprocess.run(["jj", "describe", "-m", commit_msg], check=True)

        except subprocess.CalledProcessError as e:
            print(f"Error running command: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    asyncio.run(run(revision, context, model, dry_run, temperature, max_tokens))


if __name__ == "__main__":
    main()
