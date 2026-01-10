1. regex: pattern identification

#!/bin/bash

email="text@example.com"

if [[ "$email" =~ ^[a-zA-Z0-9._]+@[a-zA-Z]+\.[a-zA-Z]+$ ]]; then
  echo "Valid email"
else
  echo "Invalid email"
fi


===== ======== =========
#!/bin/bash

num=10

if [ "$num" -gt 5 ]; then
  echo "Number is greater than 5"
else


===== ======== =========

#!/bin/bash

fruits=("Apple" "Banana" "Mango")

echo "First fruit: ${fruits[0]}"

for fruit in "${fruits[@]}"
do
  echo "Fruit: $fruit"
done

======== Associative Arrays (Key-Value)

#!/bin/bash

declare -A marks
marks[Math]=90
marks[Science]=85

echo "Math marks: ${marks[Math]}"







  echo "Number is 5 or less"
fi
