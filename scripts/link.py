# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "typer>=0.15",
#     "prompt-toolkit>=3.0.52",
#     "platformdirs>=4.3",
# ]
# ///
"""
Link dotfiles from this repo into place, as listed in links.toml.

Run with `uv run scripts/link.py` for an interactive run, or pass flags (see --help).
On NixOS, Home Manager applies the same manifest (see home.nix), so this exits early.

Windows notes:
- Symlinks need Developer Mode (or an admin shell).
- Run from a normal terminal: some sandboxed apps (e.g. MSIX-packaged ones)
  redirect writes under AppData to a private copy that other programs can't see.

Authored by Claude Opus 5.5 - Effort: Medium
"""

from __future__ import annotations

import filecmp
import os
import shutil
import sys
import tomllib
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import platformdirs
import typer
from prompt_toolkit.shortcuts import choice, confirm

REPO_DIR = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = REPO_DIR / "links.toml"
PLATFORM_KEYS = {"linux": "linux", "win32": "windows", "darwin": "macos"}
# Windows error for "A required privilege is not held by the client"
ERROR_PRIVILEGE_NOT_HELD = 1314


class Style(StrEnum):
    symlink = "symlink"
    hardlink = "hardlink"
    copy = "copy"


class OnConflict(StrEnum):
    ask = "ask"
    backup = "backup"
    skip = "skip"
    overwrite = "overwrite"


class State(StrEnum):
    missing = "missing"
    symlink = "symlink"
    hardlink = "hardlink"
    copy = "copy"  # a separate file with identical contents
    stale_link = "stale link"  # a symlink pointing somewhere else, or broken
    differs = "differs"  # a separate file with different contents


@dataclass
class Link:
    name: str
    source: Path
    target: Path

    def state(self) -> State:
        t = self.target
        if t.is_symlink():
            return (
                State.symlink
                if t.resolve() == self.source.resolve()
                else State.stale_link
            )
        if not t.exists():
            return State.missing
        if os.path.samefile(t, self.source):
            return State.hardlink
        if filecmp.cmp(t, self.source, shallow=False):
            return State.copy
        return State.differs


def placeholders() -> dict[str, str]:
    """Values for {name} placeholders in targets."""
    return {
        "home": str(Path.home()),
        "config": platformdirs.user_config_dir(),
        "localappdata": platformdirs.user_data_dir(roaming=False),
        "appdata": platformdirs.user_data_dir(roaming=True),
        "documents": platformdirs.user_documents_dir(),
    }


def load_links(manifest: Path, platform_key: str) -> list[Link]:
    data = tomllib.loads(manifest.read_text(encoding="utf-8"))
    values = placeholders()
    links = []
    for name, entry in data.items():
        targets = entry.get(platform_key, entry.get("all"))
        if targets is None:
            continue
        source = REPO_DIR / entry["source"]
        if not source.is_file():
            raise typer.BadParameter(
                f"[{name}] source not found: {source}", param_hint="manifest"
            )
        for target in [targets] if isinstance(targets, str) else targets:
            try:
                expanded = target.format_map(values)
            except KeyError as e:
                raise typer.BadParameter(
                    f"[{name}] unknown placeholder {e} in {target!r}",
                    param_hint="manifest",
                )
            links.append(Link(name, source, Path(os.path.expanduser(expanded))))
    return links


def is_interactive() -> bool:
    return sys.stdin.isatty() and sys.stdout.isatty()


def backup_path(target: Path) -> Path:
    candidate = target.with_name(target.name + ".bak")
    if candidate.exists() or candidate.is_symlink():
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        candidate = target.with_name(f"{target.name}.{stamp}.bak")
    return candidate


def create(link: Link, style: Style) -> None:
    link.target.parent.mkdir(parents=True, exist_ok=True)
    try:
        match style:
            case Style.symlink:
                link.target.symlink_to(link.source)
            case Style.hardlink:
                link.target.hardlink_to(link.source)
            case Style.copy:
                shutil.copy2(link.source, link.target)
    except OSError as e:
        if getattr(e, "winerror", None) == ERROR_PRIVILEGE_NOT_HELD:
            raise OSError(
                "symlinks need Developer Mode or an admin shell on Windows"
            ) from e
        raise


def plan_action(link: Link, style: Style) -> str:
    """What applying `link` would do: ok, create, replace, or conflict."""
    state = link.state()
    if state == style:
        return "ok"
    if state is State.missing:
        return "create"
    if state is State.differs:
        return "conflict"
    # Stale links, and other styles of an identical file, are safe to replace
    return "replace"


ACTION_COLORS = {
    "ok": typer.colors.GREEN,
    "create": typer.colors.CYAN,
    "replace": typer.colors.YELLOW,
    "conflict": typer.colors.RED,
}


def print_plan(plan: list[tuple[Link, str]]) -> None:
    width = max(len(link.name) for link, _ in plan)
    for link, action in plan:
        typer.secho(f"  {action:<8}", fg=ACTION_COLORS[action], nl=False)
        typer.echo(f" {link.name:<{width}}  {link.target}")


def resolve_conflict(link: Link, on_conflict: OnConflict) -> OnConflict:
    if on_conflict is not OnConflict.ask:
        return on_conflict
    return choice(
        message=f"{link.target} exists and differs from {link.source.name}. What should happen?",
        options=[
            (OnConflict.backup, "Back it up, then link"),
            (OnConflict.skip, "Skip it"),
            (OnConflict.overwrite, "Overwrite it"),
        ],
        default=OnConflict.backup,
    )


def check_platform(force: bool) -> str:
    if sys.platform not in PLATFORM_KEYS:
        typer.secho(
            f"Unsupported platform: {sys.platform}", fg=typer.colors.RED, err=True
        )
        raise typer.Exit(1)
    if Path("/etc/NIXOS").exists() and not force:
        typer.echo(
            "On NixOS, Home Manager applies links.toml (see home.nix). Use --force to link anyway."
        )
        raise typer.Exit(0)
    return PLATFORM_KEYS[sys.platform]


app = typer.Typer(help=__doc__.strip().split("\n\n")[0], add_completion=False)

ManifestOption = Annotated[
    Path,
    typer.Option(
        "--manifest", "-m", help="Manifest to read.", exists=True, dir_okay=False
    ),
]
OnlyOption = Annotated[
    list[str] | None,
    typer.Option("--only", "-o", help="Only these entry names (repeatable)."),
]


@app.callback(invoke_without_command=True)
def main(ctx: typer.Context) -> None:
    if ctx.invoked_subcommand is None:
        ctx.invoke(link)


@app.command()
def link(
    style: Annotated[
        Style | None,
        typer.Option("--style", "-s", help="Link style. Prompts if omitted."),
    ] = None,
    dry_run: Annotated[
        bool | None,
        typer.Option(
            "--dry-run/--apply", help="Only show the plan, or apply without asking."
        ),
    ] = None,
    on_conflict: Annotated[
        OnConflict | None,
        typer.Option(
            "--on-conflict", "-c", help="What to do with existing files that differ."
        ),
    ] = None,
    only: OnlyOption = None,
    manifest: ManifestOption = DEFAULT_MANIFEST,
    force: Annotated[bool, typer.Option("--force", help="Run even on NixOS.")] = False,
) -> None:
    """Create links for this platform (the default command)."""
    platform_key = check_platform(force)
    links = [
        l for l in load_links(manifest, platform_key) if not only or l.name in only
    ]
    if not links:
        typer.echo("Nothing to link.")
        return
    interactive = is_interactive()

    if style is None:
        style = (
            choice(
                message="Link style?",
                options=[
                    (
                        Style.symlink,
                        "symlink: edits in either place are the same file (recommended)",
                    ),
                    (
                        Style.hardlink,
                        "hardlink: no symlink rights needed, but editors that replace files break it",
                    ),
                    (Style.copy, "copy: independent copies, re-run to update"),
                ],
                default=Style.symlink,
            )
            if interactive
            else Style.symlink
        )
    if on_conflict is None:
        on_conflict = OnConflict.ask if interactive else OnConflict.backup

    plan = [(l, plan_action(l, style)) for l in links]
    typer.echo(f"Plan ({style}, {platform_key}):")
    print_plan(plan)
    if all(action == "ok" for _, action in plan):
        typer.secho("Everything is already linked.", fg=typer.colors.GREEN)
        return
    if dry_run is None:
        dry_run = interactive and not confirm("Apply these changes?")
    if dry_run:
        typer.echo("Dry run, nothing changed.")
        return

    failures = 0
    for l, action in plan:
        if action == "ok":
            continue
        try:
            if action == "conflict":
                decision = resolve_conflict(l, on_conflict)
                if decision is OnConflict.skip:
                    typer.echo(f"  skipped  {l.target}")
                    continue
                if decision is OnConflict.backup:
                    backup = backup_path(l.target)
                    l.target.rename(backup)
                    typer.echo(f"  backup   {l.target} -> {backup.name}")
                else:
                    l.target.unlink()
            elif action == "replace":
                l.target.unlink()
            create(l, style)
            typer.secho(
                f"  {'copied' if style is Style.copy else 'linked':<8} {l.target}",
                fg=typer.colors.GREEN,
            )
        except OSError as e:
            failures += 1
            typer.secho(f"  failed   {l.target}: {e}", fg=typer.colors.RED, err=True)
    if failures:
        raise typer.Exit(1)


@app.command()
def status(
    only: OnlyOption = None,
    manifest: ManifestOption = DEFAULT_MANIFEST,
) -> None:
    """Show the current state of each target."""
    platform_key = PLATFORM_KEYS.get(sys.platform, sys.platform)
    links = [
        l for l in load_links(manifest, platform_key) if not only or l.name in only
    ]
    width = max((len(l.name) for l in links), default=0)
    colors = {
        State.symlink: typer.colors.GREEN,
        State.hardlink: typer.colors.GREEN,
        State.copy: typer.colors.CYAN,
        State.missing: typer.colors.YELLOW,
    }
    for l in links:
        state = l.state()
        typer.secho(f"  {state:<10}", fg=colors.get(state, typer.colors.RED), nl=False)
        typer.echo(f" {l.name:<{width}}  {l.target}")


if __name__ == "__main__":
    app()
