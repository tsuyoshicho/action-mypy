import json
import sys


def mypy_to_rdjson(jsonin: TextIO):
    mypy_json: Dict = json.load(jsonin)

    rdjson: Dict[str, Any] = {
        "source": {"name": "mypy", "url": "https://github.com/python/mypy"},
        "severity": "WARNING",
        "diagnostics": [],
    }

    return json.dumps(rdjson)


if __name__ == "__main__":
    print(mypy_to_rdjson(sys.stdin))
