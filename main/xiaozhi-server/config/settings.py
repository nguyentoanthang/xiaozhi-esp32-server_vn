import os
import asyncio
from config.config_loader import get_project_dir, load_config


default_config_file = "config.yaml"
config_file_valid = False


def check_config_file():
    global config_file_valid
    if config_file_valid:
        return
    """
    Simplified config check that only informs the user about config file usage
    """
    custom_config_file = get_project_dir() + "data/." + default_config_file
    if not os.path.exists(custom_config_file):
        raise FileNotFoundError(
            "Cannot find the data/.config.yaml file; please follow the tutorial to confirm it exists"
        )

    # Build the config once (opens the database) to fail early if it cannot be read
    asyncio.run(load_config())
    config_file_valid = True
