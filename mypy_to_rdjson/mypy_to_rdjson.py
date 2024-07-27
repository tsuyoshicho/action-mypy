```
This code based on https://github.com/jordemort/action-pyright/blob/main/pyright_to_rdjson/pyright_to_rdjson.py
Original license :
MIT License

Copyright (c) 2021 Jordan Webb
URL: https://github.com/jordemort/action-pyright/blob/main/LICENSE
```

import json
import sys

from typing import Any, Dict, TextIO


def pyright_to_rdjson(jsonin: TextIO):
    pyright: Dict = json.load(jsonin)

    if "generalDiagnostics" not in pyright:
        raise RuntimeError("This doesn't look like pyright json")

    rdjson: Dict[str, Any] = {
        "source": {"name": "pyright", "url": "https://github.com/Microsoft/pyright"},
        "severity": "WARNING",
        "diagnostics": [],
    }

    d: Dict
    for d in pyright["generalDiagnostics"]:
        message = d["message"]

        # If there is a rule name, append it to the message
        rule = d.get("rule", None)
        if rule is not None:
            message = f"{message} ({rule})"

        rdjson["diagnostics"].append(
            {
                "message": message,
                "severity": d["severity"].upper(),
                "location": {
                    "path": d["file"],
                    "range": {
                        "start": {
                            # pyright uses zero-based offsets
                            "line": d["range"]["start"]["line"] + 1,
                            "column": d["range"]["start"]["character"] + 1,
                        },
                        "end": {
                            "line": d["range"]["end"]["line"] + 1,
                            "column": d["range"]["end"]["character"] + 1,
                        },
                    },
                },
            }
        )

    return json.dumps(rdjson)


if __name__ == "__main__":
    print(pyright_to_rdjson(sys.stdin))
