# for loop

import numpy as np

# function range():
# range(p1, p2, p3)
# p1 -> start
# p2 -> end (not included)
# p3 -> step (optionally) - byDefault 1
'''
Docstring for 11th Jan.app4

# for i in {1..5..1}; do
for i in range(10):
    print("Iteration:", i)

# range(number): 0 to number-1

for j in range(1,10,1):
    print("Count:", j)

# range(start,end,step): 0 to end-1 with step

for k in range(10,1,-2):
    print("Count12:", k)


'''

count = 1

while count <= 3:
    print("Retry attempt:", count)
    count += 1

# tab in windows -> 4 spaces
# tab in linux / mac -> not 4 spaces