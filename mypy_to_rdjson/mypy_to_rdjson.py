"""
This code based on https://github.com/jordemort/action-pyright/blob/main/pyright_to_rdjson/pyright_to_rdjson.py
Original license :
MIT License

Copyright (c) 2021 Jordan Webb
URL: https://github.com/jordemort/action-pyright/blob/main/LICENSE
"""

import json
import sys
from typing import (Any, Dict, List, TextIO)


def mypy_to_rdjson(jsonlines: TextIO):
    # "$schema": "https://raw.githubusercontent.com/reviewdog/reviewdog/master/proto/rdf/jsonschema/DiagnosticResult.json",
    rdjson: Dict[str, Any] = {
        "source": {
            "name": "mypy",
            "url": "https://mypy-lang.org/",
        },
        "severity": "WARNING",
        "diagnostics": [],
    }

    mypy_result: List = []
    try:
        for json_item in jsonlines.readlines():
            mypy_result.append(json.loads(json_item))
    except Exception:
        # decode error, return data nothing JSON
        return json.dumps(rdjson)

    d: Dict
    for d in mypy_result:
        message = d["message"]

        # If there is a rule name, append it to the message
        error_code = d.get("code", None)
        if error_code is not None:
            message = f"{message} [{error_code}]"

        # mypy errror context: ignore it. not support display (line&column are undefined)
        #  severity: note
        #  line and column: -1,-1
        if (d["severity"].upper() == "NOTE"
                and int(d["line"]) == -1
                and int(d["column"]) == -1):
            continue

        rdjson["diagnostics"].append({
            "message": message,
            "severity": d["severity"].upper(),
            "location": {
                "path": d["file"],
                "range": {
                    "start": {
                        "line": d["line"],
                        "column": d["column"],
                    },
                },
            },
        })

    return json.dumps(rdjson)


if __name__ == "__main__":
    print(mypy_to_rdjson(sys.stdin))
