#!/bin/python

# Python loops and conditionals example

def gatherinfo():
    height = float(raw_input("What's your height? (in/m) "))
    weight = float(raw_input("What's your weight? (lb/kg) "))
    unit = raw_input("Are you using metric or imperial? ")
    return(height,weight,unit)

def calculation(height,weight,unit):
    if unit=="imperial":
        bmi=703*(weight/(height**2))
    elif unit=="metric":
        bmi=weight/(height**2)
    print("Your BMI is %s" % bmi)

while True:
    height,weight,unit=gatherinfo()
    if height<=0 or weight<=0:
        print("Height and weight must be greater than zero")
    elif unit.startswith('i'):
        calculation(height,weight,unit="imperial")
        break
    elif unit.startswith('m'):
        calculation(height,weight,unit="metric")
        break
    else:
        print("Unknown measurement system %s" % unit)
