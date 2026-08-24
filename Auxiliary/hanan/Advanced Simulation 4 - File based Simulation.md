VHDL
File based Simulation
©Hanan Ribo
1

File based Simulation
• A file type provides access to objects containing a sequence of values of a
given type.
• File types are typically used to access files in the host system environment
for read, write and append operations, the value of a file object is the
sequence of values contained in the physical file.
• Using files we can enhance the simulation and validation options and
stimulate and examine our design in different ways.
©Hanan Ribo 2

| Read | and Write | File Test Bench Architecture |
| ---- | --------- | ---------------------------- |
Let's focus on this part
©Hanan Ribo
3

| Read | and Write | using TextIO | Library procedures |
| ---- | --------- | ------------ | ------------------ |
Read
Write
©Hanan Ribo
4

Read and Write using TextIO Library procedures
• Read from File in VHDL using TextIO Library
• Write to File in VHDL using TextIO Library
©Hanan Ribo 5

Test bench stimulus using file reading
©Hanan Ribo 6

Test bench stimulus using file reading – Example1
External sampling time generator
Trigger signals used by file read operations
File location strings
©Hanan Ribo 7

Test bench stimulus using file reading – Example1
File Reading Trigger
Auxiliary Data
Reading iterations Reading Mechanism
Design input stimulation
Beginning of each legal Reading
©Hanan Ribo 8

Test bench stimulus using file reading – Example1
©Hanan Ribo 9

Test bench stimulus using file reading – Example2
Internal absolute sampling time information
©Hanan Ribo 10

Test bench stimulus using file reading – Example2
Beginning of each legal Reading
©Hanan Ribo 11

Test bench stimulus using file reading – Example3
Internal relative sampling time information
©Hanan Ribo 12

Test bench stimulus using file reading – Example3
Beginning of each legal Reading
©Hanan Ribo 13

Test bench results retention using list file exporting
• As we saw, simulation results can be seen using wave and list visualization
forms.
• After sim and run operations choose the list form view and choose the way
you prefer to see the results (type in the Transcript window):
 With delta expansion: configure list -delta all
 Without delta expansion: configure list -delta collapse
• We can export the list visualization out to a txt file using the next command
(the file location is to be the project folder – default location):
write list name.lst
• We can export the list visualization out to a txt file using a specific path
location:
write list C:/Test/ModelSim/Adder/name.lst
©Hanan Ribo 14

Test bench results retention using file writing – Example4
©Hanan Ribo 15

Test bench results retention using file writing – Example4
©Hanan Ribo 16

Test bench results retention using file writing – Example4
Trigger signals
Information signals
Auxiliary Data
Writing Mechanism
Writing iterations
End of file condition
©Hanan Ribo 17

Advanced Simulation using file reading and writing – Example5
We focus on this part
©Hanan Ribo 18

Advanced Simulation using file reading and writing – Example5
Input file Output file
©Hanan Ribo 19

Advanced Simulation using file reading and writing – Example5
Design Stimulus signals
Design Response signals
Trigger signals used by file
read and write operations
File location strings
©Hanan Ribo 20

Advanced Simulation using file reading and writing – Example5
DUT = Design
Under Test
File Reading Trigger
Auxiliary Data
Set file header
©Hanan Ribo 21

Advanced Simulation using file reading and writing – Example5
Write
Reading of Update
stimulus Read
stimulus data
from input
file
Write
after Read
iterations
Input file
DUT Stimulation
Write DUT
response to
file
Check this out as a DUT
stimulation and discern What's
Output file happening
©Hanan Ribo 22

Advanced Simulation using file reading and writing – Example5
©Hanan Ribo 23