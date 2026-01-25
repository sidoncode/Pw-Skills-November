
first create a folder - then trigger the venv:

# Create virtual environment

>> python -m venv 24jan
Windows venv Activation:
>> 24jan\Scripts\activate

MacOs - Activation
>> python3 -m venv venv
>> source venv/bin/activate


===== ===== ===== ===== install request module	===== ===== ===== ===== 
>> pip install requests
======= app1.py =======

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
print("Response Body:", response.text)

print("======")
print("Headers:", response.headers)
print("response.url:", response.url)
print("response in json formatting:", response.json)

====== ====== ====== 	====== app2.py	====== ====== ====== ====== ====== ====== ====== 

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

====== installting bs4 and lxml libs =========

>> pip install beautifulsoup4 lxml

======== code ====

# Get HTML (real website)

import requests
from bs4 import BeautifulSoup

url = "https://quotes.toscrape.com"
response = requests.get(url)

html = response.text

# Create BeautifulSoup object

soup = BeautifulSoup(html, "html.parser")

# View HTML structure

print(soup.prettify())

# view h1 tag

print(soup.h1.text)

# view h1 tag
title = soup.find("h1")
print(title.text)



=====


import requests
from bs4 import BeautifulSoup

# Step 1: website URL
url = "https://quotes.toscrape.com"

# Step 2: download HTML
response = requests.get(url)

# Step 3: parse HTML
soup = BeautifulSoup(response.text, "html.parser")

# classes -> to scrape data
'''
text: quote
author: name of the author
'''

# Step 4: find all quote blocks
quotes = soup.find_all("div", class_="quote")

# Step 5: extract data
for q in quotes:
    text = q.find("span", class_="text").text
    author = q.find("small", class_="author").text

    print("Quote:", text)
    print("Author:", author)
    print("-" * 50)
    
    


==== numpy and pandas ======
before running the code install numpy in - Venv

>> pip install numpy

#numpy -> module for numerical operations
# python -> =,-,*,/,%,//,**
# 1d dataSet


import numpy as np

arr = np.array([10, 20, 30, 40, 50])
print(arr)
'''
print(arr + 10)
print(arr * 2)
print(arr / 2)
'''
print(np.zeros(5))
print(np.ones(5))
print(np.random.randint(1, 100, 5))


data = np.array([12, 15, 18, 20, 25])

print("Mean:", np.mean(data))
print("Max:", np.max(data))
print("Min:", np.min(data))
print("Sum:", np.sum(data))

# boolean filtering
nums = np.array([10, 25, 30, 45, 50])

print(nums[nums > 30])


====== Pandas ======
1. create / activate the venv 
install pandas

>>pip install pandas


import pandas as pd
data = {
    "OrderID": [101, 102, 103, 104, 105],
    "Customer": ["Amit", "Neha", "Rahul", "Priya", "Karan"],
    "City": ["Delhi", "Mumbai", "Pune", "Delhi", "Bangalore"],
    "Product": ["Laptop", "Mobile", "Tablet", "Laptop", "Mobile"],
    "Quantity": [1, 2, 1, 3, 2],
    "Price": [70000, 25000, 30000, 70000, 25000]
}

df = pd.DataFrame(data)

'''
print(df)

# display first 5 rows and last 5 rows
print("First 5 rows:", df.head())
print("Last 5 rows:", df.tail())

# information about the DataFrame
print("\nDataFrame Info:", df.info())

# statistical summary of numerical columns
print("\nStatistical Summary:\n", df.describe())

'''

# filering data
# Orders from Delhi
print(df[df["City"] == "Delhi"])

# Amount greater than 50,000
print(df[df["Price"] > 50000])    


#sorting  data

print(df.sort_values(by="Price", ascending=False))



#sorting  data

print(df.sort_values(by="Price", ascending=False))

# Aggregations
print("\nTotal Quantity Sold:", df["Quantity"].sum())
print("Average Price of Products:", df["Price"].mean()) 

# select rows

print(df.iloc[0])        # by index
print(df.loc[2]   )      # by label

# apply function

def apply_discount(price):
    return price * 0.9  # 10% discount

df["Discounted_Price"] = df["Price"].apply(apply_discount)
print(df)


  # Read & Write CSV

  df.to_csv("sales.csv", index=False)


  # group by city using price columns
  df.groupby("City")["TotalAmount"].sum()


========== Exercise ===============


import pandas as pd

data = {
    "EmpID": [101, 102, 103, 104, 105, 106],
    "Name": ["Amit", "Neha", "Rahul", "Priya", "Karan", "Sneha"],
    "Department": ["IT", "HR", "IT", "Finance", "HR", "IT"],
    "City": ["Delhi", "Mumbai", "Pune", "Delhi", "Mumbai", "Bangalore"],
    "Salary": [60000, 45000, 70000, 55000, 48000, 75000],
    "Experience": [3, 2, 5, 4, 2, 6]
}

df = pd.DataFrame(data)

Task 1: Basic Exploration
 - Display first 5 records
 - Display last 3 records
 - Check dataset shape
 - Check column names
 - Display dataset info
 
Task 2: Column Operations
 - Display only Name and Salary
 - Add a new column Bonus = 10% of Salary -> Using function
 - Show employees with salary greater than 60,00
 - Sort employees by salary (descending)
 - Find average salary
 - Find maximum salary


