import toml
import sys

content = toml.load(f"{sys.argv[1]}/Cargo.toml")
print(f'{content.get("package", {}).get("name")}:{content.get("package", {}).get("version")}')
