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


# filering data
# Orders from Delhi
print("Orders from Delhi:")
print(df[df["City"] == "Delhi"])

print("\n")
# Amount Price than 50,000
print(df[df["Price"] > 50000])    

#sorting  data

print(df.sort_values(by="Price", ascending=False))

# Aggregations
print("\nTotal Quantity Sold:", df["Quantity"].sum())
print("Average Price of Products:", df["Price"].mean()) 



# select rows

print(df.iloc[0])        # by index
print(df.loc[2]   )      # by label

# apply function

def mrBean(price):
    return price * 0.9  # 10% discount

df["Discounted_Price"] = df["Price"].apply(mrBean)
print(df)


# Read & Write CSV

df.to_csv("sales.csv", index=False)
'''
print(df)
print("====")
# group by city using price columns
print(df.groupby("City")["Price"].sum())

