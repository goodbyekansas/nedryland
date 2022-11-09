from setuptools import setup, find_packages

pkgs = find_packages()
pkgs_data = {name: ["**/*.pyi", "**/py.typed", "py.typed", "*.pyi"] for name in pkgs}

setup(
    name="@packageName@",
    version="@version@",
    author="Dennis Nedry",
    author_email="dennis.nedry@jpark.com",
    description="Python type definitions for @packageName@",
    packages=pkgs,
    package_data=pkgs_data,
    include_package_data=True,
    zip_safe=False,
)
