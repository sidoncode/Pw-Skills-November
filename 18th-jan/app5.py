from datetime import datetime
'''
current_time = datetime.now()
print(current_time)

today = datetime.today()
print(today)


# datetime.today() vs datetime.now() -> return same
datetime.today() -> date / time (both in same string)
datetime.now() -> same now -> today

# datetime.now().date() vs datetime.now.time()
datetime.now().date() -> only date
datetime.now().time() -> only time




from datetime import datetime

now = datetime.now()
print(now.strftime("%d-%m-%Y"))
print(now.strftime("%d %B %Y"))


%d -> date
%m -> month (number)
%B -> month (full name)
%Y -> year (4 digit)



# date difference

from datetime import date

d1 = date(2026, 1, 1)
d2 = date.today()

print(d2 - d1)
'''

# Paras -> 12th december from now time(hrs)
# diff -> hrs(time)
# paras 12th december 1999 (time) 10:10am IST
# datetime.now().time() -> current time

now = datetime.now()
birthday = datetime(now.year, 12, 12, 10, 10)

diff = birthday - now
print(diff)

