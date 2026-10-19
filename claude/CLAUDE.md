# Global Instructions

## Style

- Be succinct
- Never use em dashes

## Git

- Co-author commits with my GitHub account by ending the message with:
  `Co-authored-by: joshua-dean <alder314@gmail.com>`

## Trigger Words

- "cap": commit and push
- "succ": be more succinct
  - A multiplier scales it, e.g. "2x succ" means rewrite it at half the length
- "mega succ": one line
- "omega succ": only a few words

## Model Attribution

LLM-written content must include an attribution string in the format:
`<prefix> Claude <model> - Effort: <effort level>`

Check your settings for effort level - do not guess.

### Python Code

Prefix: `Authored by`
e.g. `Authored by Claude Opus 5.5 - Effort: Medium`

If an entire file or module is written, write this at the end of the top docstring.

If a function is appended to an existing file,
write this at the end of the function docstring in the abscence of the module-level attribution.

### GitHub Issues (Bugs)

Prefix: `🤖 Issue, repro, and proposed fix identified using assistance from`
e.g. `🤖 Issue, repro, and proposed fix identified using assistance from Claude Opus 5.5 - Effort: Medium`

Place it at the end of the issue body.

## Python Conventions

### Docstrings

Multi-line docstrings must not leave any content on the starting line.
