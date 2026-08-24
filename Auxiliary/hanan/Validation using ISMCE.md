ISMCE
(In-System Memory
Content Editor)

Quartus configuration to VHDL 2008 version

Open ISMCE

Digital System Design Loading

2. Load the
design file *.sof
to the FPGA
chip only once
per design cycle

1. Set the HW
connection

Validation using ISMCE
Running applications
(recurring steps)

Step 1 – Load the application’s code segment bin file

2. Write the ITCM.hex content to the physical ITCM memory

1. Import the binary file ITCM.hex of an application code segment

Step 2 – Load the application’s data segment bin file

2. Write the DTCM.hex content to the physical DTCM memory

1. Import the binary file DTCM.hex of an application code segment

Step 3 – Run the application

1. Click the RESET pushbutton (KEY0) to run the application

3. Read data from the physical DTCM memory

2. Choose the DTCM memory

Step 4 – Validation using the golden model

1. Export the content of the physical DTCM memory to a DTCM.hex file

2. Open the application in RARS and run it until reaching its endpoint.
3. Create a DTCM.hex file from RARS (at the application’s endpoint).
4. Use TextDiff.exe application to validate the equality of the content of both
files DTCM.hex from clauses 1 and 3.

Run a new application
(return on steps 1-4)

