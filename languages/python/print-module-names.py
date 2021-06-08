from distutils.core import run_setup


def print_module_names() -> None:
    """ Print everything in setup.py's py_modules and packages """
    res=run_setup("./setup.py", stop_after="init")
    print(" ".join(res.packages or [] + map(lambda x: f"{x}.py", res.py_modules or [])))


if __name__ == "__main__":
    print_module_names()
