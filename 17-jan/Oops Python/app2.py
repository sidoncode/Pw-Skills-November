#inheritance example
#single level inheritance
class Parent:
    def house(self):
        print("Parent house")

class Child(Parent):
    def car(self):
        print("Child car")

c = Child()
c.house()
c.car()
