# basic string Manipulation functions

text = " Hello, World! "
'''
print(text.strip())        # Remove leading and trailing whitespace
print(text.lower())        # Convert to lowercase
print(text.upper())        # Convert to uppercase
print(text.replace("World", "Python"))  # Replace substring 
print(text.split(","))    # Split string by comma
print(text)
print(text.isupper())        # Check if all characters are uppercase

'''

print(len(text))          # Get length of the string inclusive of spaces
print(text.find("World")) # Find substring index
print(text.startswith(" Hello")) # Check if string starts with a substring
print(text.endswith("! "))      # Check if string ends with a substring