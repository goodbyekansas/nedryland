import os
import sys
import re
from pathlib import Path
from configparser import ConfigParser

import toml


def merge(source: dict, destination: dict) -> dict:
    for key, value in source.items():
        if isinstance(value, dict):
            node = destination.setdefault(key, {})
            merge(value, node)
        else:
            destination[key] = value

    return destination


def change_header(config: dict, from_header: str, to_header: str) -> dict:
    sub_config = config
    if from_header:
        sub_keys = from_header.split(".")
        for sub_key in sub_keys:
            if _sub_config := sub_config.get(sub_key):
                sub_config = _sub_config
            else:
                return {}

    return {to_header: sub_config}


def parse_toml(config_file: str) -> dict:
    with open(config_file) as cfg:
        return toml.load(cfg)


def parse_ini(config_file: str) -> dict:
    config = ConfigParser()
    config.read(config_file)
    return config._sections

def parse_lists_for_toml(config_file) -> None:
    for key, value in config_file.items():
        if isinstance(value,str):
            arr = re.sub("\s*|\r?\n|#.*$", "", value, flags=re.MULTILINE).rstrip(",").split(",")
            
            if len(arr) > 1:
                config_file[key] = arr

        elif isinstance(value, dict):
            parse_lists_for_toml(value)


if __name__ == "__main__":
    tool_name = sys.argv[1]
    files = sys.argv[2:]
    combined_config = {}
    out_file = Path(os.environ["out"])

    for config_file, key in filter(
        lambda cfg: cfg[0].exists(),
        map(
            lambda item: (Path(item.split("=")[0]),
            item.split("=")[1]), files,
        ),
    ):
        print(f"Using {tool_name} settings from {config_file.absolute()}")
        match config_file.suffix:
            case ".toml":
                read_config = parse_toml(config_file)
            case _:
                read_config = parse_ini(config_file)
                if out_file.suffix == ".toml" and tool_name == "pylint":
                    parse_lists_for_toml(read_config)
        read_config = change_header(read_config, key, tool_name)
        combined_config = merge(combined_config, read_config)

    with open(out_file, "w") as output_file:
        if out_file.suffix == ".toml":
            toml.dump({ "tool": combined_config }, output_file)
        else:
            config_parser = ConfigParser()
            config_parser.read_dict(combined_config)
            config_parser.write(output_file)

