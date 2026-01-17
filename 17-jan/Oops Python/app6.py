# abstraction -
from abc import ABC, abstractmethod


# class define -> abstract class
# every abstract class must have at least one abstract method

class Vehicle(ABC):

# we are defing the abstract method - but we are not providing the implementation
    @abstractmethod
    def start(self):
        pass

class Bike(Vehicle):
    # for the abstract method we are providing the implementation
    def start(self):
        print("Bike started")

b = Bike()
b.start()
