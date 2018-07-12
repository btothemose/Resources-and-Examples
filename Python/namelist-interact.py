#!/bin/python

import os

namelist=open('namelist.txt', 'a')
# Default open type is 'r' for read. Write must be
# specified 'w', and read/write 'r+'. 'a' gives
# appending properties

# namelist.write("Textname\n")
# Will add text to file, but it will replace text
# Because the cursor starts at 0

# namelist.seek(-1, os.SEEK_END)
# Brings the cursor to the very start of the file,
# allowing you to write from the start
# namelist.write("\nTextname\n")
# namelist.write("Textname\n")

namelist.writelines(['Line1\n', 'Line2\n'])

# print(namelist.read())
# Prints entire file exactly as is

#for line in namelist:
#    print(line)
# Prints file with new line breaks between lines

namelist.close()

# To turn file calling into an individual function instance,
# and dismissing the need to close use a with loop as follows:
# with open('namelist.txt', 'a') as namelist:
#       namelist.write("Nameentry\n")
