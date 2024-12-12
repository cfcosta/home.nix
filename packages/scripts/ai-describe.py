#!/usr/bin/env python312
"""Generate commit messages using LLM and describe JJ commits."""

import asyncio
import os
import string
import subprocess
import sys
from typing import Any, cast

import litellm


PROMPT_TEMPLATE = string.Template("""
You are an expert software engineer who creates concise, one-line Git commit messages and then provides a detailed, factual explanation of the changes.

**Context**:
```
${TASK_CONTEXT}
```

**Commit Summary**:
```
${CURRENT_SUMMARY}
```

**Commit Contents**:
```
${CURRENT_DIFF}
```

**Instructions**:

1. **Commit Message (First Line)**:
   - Review the provided context and diff.
   - Produce a single-line commit message of the form:
     ```
     <type>(<program>): <description>
     ```
     where:
     - `<type>` ∈ {`fix`, `feat`, `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`}
     - `<program>` is one of the available "sections" of this repository (e.g., `ingest`, `review`).
     - `<description>` uses the imperative mood and fits within 72 characters total.
   
2. **Explanation (Subsequent Lines)**:
   - After the commit message, add a blank line.
   - Provide a neutral, factual explanation of the reasoning, background, and context behind the changes.
   - Avoid instructions, opinions, or subjective descriptions.
   - Use E-Prime (omit forms of "be") and adhere to a reference-like style: concise, clear, and authoritative.
   - Consider alternatives and explain why the chosen approach fits best.
   
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


def get_jj_files() -> list[str]:
    """Get list of files tracked by jj, excluding CURRENT_TASK.md."""
    files = run_command(["jj", "files", "list"]).splitlines()
    return [f for f in files if f != "CURRENT_TASK.md"]


def get_context() -> dict:
    """Gather all the context needed for the commit message."""
    return {
        "CURRENT_SUMMARY": run_command(["jj", "show", "--summary"]),
        "CURRENT_DIFF": run_command(["jj", "diff", "-r", "@-..@", *get_jj_files()]),
        "TASK_CONTEXT": run_command(["jj", "diff", "-r", "@-..@", "./CURRENT_TASK.md"]),
    }


async def generate_commit_message(context: dict) -> str:
    """Generate a commit message using LLM."""
    prompt = PROMPT_TEMPLATE.substitute(context)

    full_message = []
    model = os.getenv("AI_MODEL", "cerebras/llama-3.3-70b")
    print(f"Generating commit message using {model}:", file=sys.stderr)

    async for chunk in await litellm.acompletion(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=1.0,
        max_tokens=1024,
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


async def main():
    """Main function to generate and apply commit message."""
    try:
        context = get_context()
        commit_msg = await generate_commit_message(context)

        # Apply the commit message using jj describe
        subprocess.run(["jj", "describe", "-m", commit_msg], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
