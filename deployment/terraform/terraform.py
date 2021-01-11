"""
Terraform deployment wrapper
"""

import os
import os.path
import argparse
import shutil
import tempfile
import pathlib
import contextlib
import typing
import subprocess


@contextlib.contextmanager
def _setup_sources(source: pathlib.Path) -> typing.Iterator[pathlib.Path]:
    """
    Copies sources to a temp directory.
    """
    with tempfile.TemporaryDirectory() as tmp_dir:
        print(f"Using temporary directory {tmp_dir}")
        shutil.copytree(src=source, dst=tmp_dir, dirs_exist_ok=True)
        os.chmod(tmp_dir, 0o755)
        yield pathlib.Path(tmp_dir)


def _run_terraform(
    cwd: pathlib.Path, command: str, args: typing.List[str] = None
) -> None:
    subprocess.check_call(
        ["terraform", command, "-lock-timeout=300s", "-input=false"] + (args or []),
        cwd=cwd,
    )


def apply(args: argparse.Namespace) -> None:
    """
    Applies the terraform plan
    """
    with _setup_sources(pathlib.Path(args.source)) as tmp_dir:
        _run_terraform(cwd=tmp_dir, command="init")
        _run_terraform(cwd=tmp_dir, command="apply", args=["-auto-approve"])


def plan(args: argparse.Namespace) -> None:
    """
    Plans the terraform
    """
    with _setup_sources(pathlib.Path(args.source)) as tmp_dir:
        _run_terraform(cwd=tmp_dir, command="init")
        _run_terraform(
            cwd=tmp_dir,
            command="plan",
            args=["-no-color"] + ([f"-out={args.out}"] if args.out else []),
        )


def main() -> None:
    """
    The main method of this program. Pls use as entrypoint.
    """
    parser = argparse.ArgumentParser(description="Terraform deployment wrapper")
    subparsers = parser.add_subparsers(
        help="sub-command help", title="Sub commands", dest="subcommand"
    )

    parser.add_argument(
        "--source", type=str, help="Path to the terraform sources", required=True
    )
    sub_apply = subparsers.add_parser("apply", help="Applies the terraform plan.")
    sub_apply.set_defaults(func=apply)

    sub_plan = subparsers.add_parser(
        "plan", help="Creates a terraform plan without applying anything."
    )
    sub_plan.add_argument(
        "--out", type=str, help="Path to output terraform plan, default is stdout"
    )
    sub_plan.set_defaults(func=plan)

    args = parser.parse_args()

    try:
        if args.subcommand is None:
            apply(args)
        else:
            args.func(args)
    except subprocess.CalledProcessError as cpe:
        print(f"Failed to run terraform: {cpe}")


if __name__ == "__main__":
    main()
