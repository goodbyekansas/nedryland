""" Package setup for the component awesome-client """
from setuptools import find_packages, setup

setup(
    name="awesome-client",
    version="0.1.0",
    url="internet.com",
    author="Documentor",
    author_email="person@internet.com",
    description="client for interacting with the awesome service",
    packages=find_packages(),
    entry_points={"console_scripts": ["awesome-client=awesome_client.main:main"]},
)
