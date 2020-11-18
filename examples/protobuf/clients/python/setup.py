from setuptools import setup

setup(
    name="protobuf-client-example",
    version="0.1.0",
    author="GBK Pipeline Team",
    author_email="pipeline@goodbyekansas.com",
    description="Example client showing transitive protobuf dependencies",
    py_modules=["protobuf_example_client"],
    entry_points={
        "console_scripts": ["protobuf_example_client=protobuf_example_client:main"],
    },
)
