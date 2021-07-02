""" This is the setup """
from setuptools import setup

setup(
    name="hello-client-example",
    version="1.0.0",
    author="GBK Pipeline Team",
    author_email="pipeline@goodbyekansas.com",
    description="Prints hello",
    py_modules=["hello"],
    entry_points={"console_scripts": ["hello=hello:main"]},
)
