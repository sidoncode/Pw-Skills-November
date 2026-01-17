# Polymorphism

class Animal:
    def sound(self):
        print("Some generic animal sound")
    
class Dog(Animal):
    def sound(self):
        print("Bark")

# creating a object of Dog class
dog_obj = Dog()
dog_obj.sound() # output: Bark

# creating a object of Animal class
Animal_obj = Animal()
Animal_obj.sound() # output: Some generic animal sound

# sound() -> but different function body BASED on class Type
# Animal -> sound() -> Some generic animal sound
# Dog -> sound() -> Bark

'''
for example:
application -> login / sign up page

login  CLASS -> password -> check Backend() -> correct / incorrect
signup CLASS -> password -> regex check -> 8charc... -> check Backend()

login -> 
'''
