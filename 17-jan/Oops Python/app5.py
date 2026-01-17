# Encapsulation

# public variable
class Demo:
    name = "Python"
    _name1 = "Java"  # protected variable
    __name2 = "C++"  # private variable 


    age = 12
    class_var = "PwSkills"

    def display(self):
        print("Public:", self.name)
        print("Protected:", self._name1)
        print("Private:", self.__name2)

    #getters -> get the values
    def get_age(self):
        return self.age
    def get_class_var(self):
        return self.class_var
    
    # this will get the private variable __name2 (value C++)
    def get__name2(self):
        print( self.__name2)
    

Demo_obj = Demo()
Demo_obj.get__name2()  # Accessing private variable via method

'''
print(Demo_obj.name)        # Accessing public variable
print(Demo_obj._name1)     # Accessing protected variable
print(Demo_obj.__name2)   # Accessing private variable (will raise an AttributeError)

print(Demo_obj.get_age())          # Accessing private variable via method
print(Demo_obj.get_class_var())   # Accessing class variable via method
'''