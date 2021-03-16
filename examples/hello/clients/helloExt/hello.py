"""
Hello print

numpy_wrapper is available because we put that as a
dependency in `project.nix`.
"""

from numpy_wrapper import array


def main() -> None:
    """
    prints hello
    """
    blah = array.get_random_array()
    print(f"HELLO {blah}")


if __name__ == "__main__":
    main()
