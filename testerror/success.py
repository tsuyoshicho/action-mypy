import requests

def mul(a: int, b: int) -> int:
    return a * b

def test_requests() -> None:
    url = 'https://httpbin.org/get'
    r = requests.get(url)
    print(r.text)

