from setuptools import setup

setup(
    name="terraform-deploy",
    version="0.1.0",
    author="GBK Pipeline Team",
    author_email="pipeline@goodbyekansas.com",
    description="Deploy script for Terraform",
    py_modules=["terraform"],
    entry_points={"console_scripts": ["terraform-deploy=terraform:main"]},
)
