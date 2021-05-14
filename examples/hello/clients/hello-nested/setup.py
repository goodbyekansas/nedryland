""" This is the setup """
from setuptools import setup

setup(
    name="hello-client-nested-example",
    version="0.1.0",
    author="GBK Pipeline Team",
    author_email="pipeline@goodbyekansas.com",
    description="Prints hello but in a component nested in a component",
    py_modules=["hello"],
    entry_points={"console_scripts": ["hello=hello:main"]},
)
