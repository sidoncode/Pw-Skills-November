import re

text = "I love python"

result = re.search("python", text)

print(result)


text = "python java python devops"

print(re.findall("python", text))

# search vs findall -> search -> keyword search
# findall -> everything