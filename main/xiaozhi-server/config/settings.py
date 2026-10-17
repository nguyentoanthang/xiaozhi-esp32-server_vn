import asyncio
from config.config_loader import load_config


config_file_valid = False


def check_config_file():
    """Build the config once to fail early if the database cannot be read.

    This opens the SQLite database (seeding it on the first start). data/.config.yaml is
    optional: a missing file simply means "use the defaults from config.yaml".
    """
    global config_file_valid
    if config_file_valid:
        return

    asyncio.run(load_config())
    config_file_valid = True
