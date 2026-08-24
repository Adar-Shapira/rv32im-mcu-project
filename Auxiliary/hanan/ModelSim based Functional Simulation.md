ModelSim

based Functional Simulation

Contents
A.  Creating a New Project: ................................................................................................................................ 2

1)

2)

3)

I.

II.

4)

5)

Step 1 – create a new project and add VHDL files: ............................................................................................ 2

Step 2 – compilation order and project full compilation: .................................................................................. 2

Step 3 – Simulation: ............................................................................................................................................ 3

Start simulation - Option 1: ............................................................................................................................ 3

Start simulation - Option 2: ............................................................................................................................ 3

Step 4 option 1 – add  signals to the simulation manually for wave or list view: ............................................ 4

Step 5 – Run the simulation and show signals resulting in Wave and List view: .............................................. 5

................................................................................................................................................................................... 5

Wave view: ............................................................................................................................................................... 5

List view: ................................................................................................................................................................... 5

6)

Step 4 option 2 – add signals to the simulation using *.do file for wave or list view: ..................................... 6

Save simulation selected signals using a wave *.do file: ........................................................................................ 6

Save simulation selected signals using a list *.do file: ............................................................................................ 6

Load selected signals from wave or list *.do file: ................................................................................................... 6

B.  Changing the VHDL source files of the project:............................................................................................... 7

C.  Open an existing project: .............................................................................................................................. 8

D.  ModelSim IDE preferences: ........................................................................................................................... 9

How to set text font and size: ...................................................................................................................................... 9

©Hanan Ribo

A.  Creating a New Project:

1)  Step 1 – create a new project and add VHDL files:

2)  Step 2 – compilation order and project full compilation:

©Hanan Ribo

3)  Step 3 – Simulation:

I. Start simulation - Option 1:

II.  Start simulation - Option 2:

Double click!

©Hanan Ribo

4)  Step 4 option 1 – add  signals to the simulation manually for wave or list view:

 :

Object

 ןולח חתפנ אלו הדימב
s

  הנושארה הרושה תא ןמסנ ,
  רחבנ ינמי ןצחלב .)

 תויורשפא יתש
א .

sim

 תינושלל שגינ
-
ה םש םע(
test bench
  .
Add Wave
View -> Objects

ב .

Wave view

List view

©Hanan Ribo

5)  Step 5 – Run the simulation and show signals resulting in Wave and List view:

Wave view:

List view:

Write in the Transcript window the next commands:
•  Show the final List results without any delta expansions:

configure list -delta collapse

•  Save a list file in the working directory:

write list name.lst

•  Save a list file using a path directory:

write list -window .main_pane.list C:/Users/revoh/Desktop/name.lst

•  Save a list file using the GUI:

©Hanan Ribo

6)  Step 4 option 2 – add signals to the simulation using *.do file for wave or list view:

Save simulation selected signals using a wave *.do file:

Save simulation selected signals using a list *.do file:

Load selected signals from wave or list *.do file:

©Hanan Ribo

B.  Changing the VHDL source files of the project:

.)ליעל ראותמכ(

 ךליאו

2

 בלשמ םיבלשה תא עצבל שי ,ךשמהל

©Hanan Ribo

C.  Open an existing project:

2 :)

 ףיעסל רובע אל םא ,חותפו הדי

מב

( יחכונה טקיורפה תא חותיפה תביבסב םירגוס

1)

 :םייקה טקיורפה תא חתפנ

2)

work

 תייקיתש אדוונ

3)

.)היצלומיס

  ןכמ רחאלו

Project

 ןולחב ףסונ לופמק עצבל ןתינ( שדחה טקיורפה רובע הנכדעתה

©Hanan Ribo

D.  ModelSim IDE preferences:
How to set text font and size:

©Hanan Ribo

