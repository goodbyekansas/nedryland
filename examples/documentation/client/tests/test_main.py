""" Tests for awesome_client in awesome-client """
import awesome_client.main


def test_main() -> None:
    """Tests for the main function"""
    assert awesome_client.main.main(3, 7) == 10
