import requests
from bs4 import BeautifulSoup

url = "https://quotes.toscrape.com"
response = requests.get(url)

website_content = response.text

# Create BeautifulSoup object

# website_content -> url -> html objects
# parse (scrap / extract) -> BS4 object
# parser will change according to the type of data we have

soup = BeautifulSoup(website_content, "html.parser")

# View HTML structure

# print(soup.prettify())

# print(soup.h1.text)

# view h1 tag
title = soup.find("h2")
print(title.text)



