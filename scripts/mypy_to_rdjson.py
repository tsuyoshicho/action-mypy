import json
import sys

from typing import Any, Dict, TextIO


def mypy_to_rdjson(jsonin: TextIO):
    mypy_json: Dict = json.load(jsonin)

    if "generalDiagnostics" not in pyright:
        raise RuntimeError("This doesn't look like pyright json")

    rdjson: Dict[str, Any] = {
        "source": {"name": "mypy", "url": "https://github.com/python/mypy"},
        "severity": "WARNING",
        "diagnostics": [],
    }

    d: Dict
    for d in mypy_json["generalDiagnostics"]:
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
    print(mypy_to_rdjson(sys.stdin))
