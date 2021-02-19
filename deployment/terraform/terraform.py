"""
Terraform deployment wrapper
"""

import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import typing


def _setup_sources(source: pathlib.Path) -> None:
    shutil.copytree(src=source, dst=os.getcwd(), dirs_exist_ok=True)
    os.chmod(path=os.getcwd(), mode=0o755)
    for root, dirs, _ in os.walk(os.getcwd()):
        for content in dirs:
            os.chmod(path=os.path.join(root, content), mode=0o755)


def _run_terraform(command: str, args: typing.List[str] = None) -> None:
    subprocess.check_call(
        ["terraform", command, "-lock-timeout=300s", "-input=false"] + (args or []),
    )


def apply(args: argparse.Namespace) -> None:
    """
    Applies the terraform plan
    """
    _setup_sources(source=args.source)
    _run_terraform(command="init")
    _run_terraform(command="apply", args=["-auto-approve"])


def plan(args: argparse.Namespace) -> None:
    """
    Plans the terraform
    """
    _setup_sources(source=args.source)
    _run_terraform(command="init")
    _run_terraform(
        command="plan", args=["-no-color"] + ([f"-out={args.out}"] if args.out else []),
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
        sys.exit(1)


if __name__ == "__main__":
    main()
