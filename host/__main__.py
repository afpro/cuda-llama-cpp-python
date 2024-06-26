"""Example FastAPI server for llama.cpp.

To run this example:

```bash
pip install fastapi uvicorn sse-starlette pydantic-settings
export MODEL=../models/7B/...
```

Then run:
```
uvicorn host.app:create_app --reload
```

or

```
python3 -m host
```

Then visit http://localhost:8000/docs to see the interactive API docs.

"""
from __future__ import annotations

import argparse
import os
import sys

import uvicorn
from llama_cpp.llama_cpp import llama_supports_gpu_offload

from .app import create_app
from .cli import add_args_from_model, parse_model_from_args
from .settings import (ConfigFileSettings, ModelSettings, ServerSettings,
                       Settings)


def main():
    description = "🦙 Llama.cpp python server. Host your own LLMs!🚀"
    parser = argparse.ArgumentParser(description=description)

    add_args_from_model(parser, Settings)
    parser.add_argument(
        "--config_file",
        type=str,
        help="Path to a config file to load.",
    )
    server_settings: ServerSettings | None = None
    model_settings: list[ModelSettings] = []
    args = parser.parse_args()
    try:
        # Load server settings from config_file if provided
        config_file = os.environ.get("CONFIG_FILE", args.config_file)
        if config_file:
            if not os.path.exists(config_file):
                raise ValueError(f"Config file {config_file} not found!")
            with open(config_file, "rb") as f:
                # Check if yaml file
                if config_file.endswith(".yaml") or config_file.endswith(".yml"):
                    import json

                    import yaml

                    config_file_settings = ConfigFileSettings.model_validate_json(
                        json.dumps(yaml.safe_load(f))
                    )
                else:
                    config_file_settings = ConfigFileSettings.model_validate_json(
                        f.read())
                server_settings = ServerSettings.model_validate(
                    config_file_settings)
                model_settings = config_file_settings.models
        else:
            server_settings = parse_model_from_args(ServerSettings, args)
            model_settings = [parse_model_from_args(ModelSettings, args)]
    except Exception as e:
        print(e, file=sys.stderr)
        parser.print_help()
        sys.exit(1)
    assert server_settings is not None
    assert model_settings is not None

    print(f'Support GPU: {llama_supports_gpu_offload()}')

    app = create_app(
        server_settings=server_settings,
        model_settings=model_settings,
    )
    for route in app.router.routes:
        print(route)

    uvicorn.run(
        app,
        host=os.getenv("HOST", server_settings.host),
        port=int(os.getenv("PORT", server_settings.port)),
        ssl_keyfile=server_settings.ssl_keyfile,
        ssl_certfile=server_settings.ssl_certfile,
        log_level="debug",
    )


if __name__ == "__main__":
    main()
