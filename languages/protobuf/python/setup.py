from setuptools import setup, find_packages

setup(
    name="@packageName@",
    version="@version@",
    author="GBK Pipeline Team",
    author_email="pipeline@goodbyekansas.com",
    description="Python type definitions for @packageName@",
    packages=find_packages(),
    package_data={"firm_protocols": ["**/*.pyi", "**/py.typed", "py.typed", "*.pyi"]},
    include_package_data=True,
    zip_safe=False,
)
