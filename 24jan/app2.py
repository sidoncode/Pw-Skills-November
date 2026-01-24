import requests

url = "https://jsonplaceholder.typicode.com/posts"

payload = {
    "title": "Python Requests",
    "body": "Learning requests library",
    "userId": 1
}

response = requests.post(url, json=payload)

print(response.status_code)
print(response.json())