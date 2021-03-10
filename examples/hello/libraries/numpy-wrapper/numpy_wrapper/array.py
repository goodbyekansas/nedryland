"""
Numpy wrapper with utility functions when we are lazy

numpy is available because they are inputs in the `numpy-wrapper.nix`
"""

import numpy  # type: ignore


def get_random_array() -> numpy.ndarray:
    """
    foo
    """

    return numpy.array([1, 2, 3])
