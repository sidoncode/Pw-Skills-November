class Father:
    def skill(self):
        print("Driving")

class Mother:
    def talent(self):
        print("Cooking")

class Child(Father, Mother):
    pass

c = Child()
c.skill()
c.talent()