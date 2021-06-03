""" Package setup for the component @pname@ """
from setuptools import find_packages, setup

setup(
    name="@pname@",
    version="@version@",
    url="@url@",
    author="@author@",
    author_email="@email@",
    description="@desc@",
    packages=find_packages(),
    entry_points=@entryPoint@,
)
