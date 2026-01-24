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