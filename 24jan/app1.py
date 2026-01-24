import requests

# get request to fetch data from a URL
url = "https://example.com"

''' APi methods 
# get -> get data from the server
# post -> insert new data to the Backend (BODY)
# put -> single entry
# delete -> delete item
# patch -> update single entry
'''


'''
response code:
200 -> success
404 -> not found
403 -> forbidden
500 -> server error
301 -> redirect
'''
response = requests.get(url)
print("Status Code:", response.status_code)
print("Response Body:", response.json)

print("======")
print("Headers:", response.headers)
print("response.url:", response.url)
print("response in json formatting:", response.json())