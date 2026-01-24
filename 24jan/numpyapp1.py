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

print(np.zeros(5))
print(np.ones(5))
print(np.random.randint(1, 100, 5))

'''

data = np.array([12, 15, 18, 20, 25])

print("Mean:", np.mean(data))
print("Max:", np.max(data))
print("Min:", np.min(data))
print("Sum:", np.sum(data))

# boolean filtering
nums = np.array([10, 25, 30, 45, 50])

print(nums[nums > 30])
