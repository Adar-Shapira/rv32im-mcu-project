Datapath & Control Unit
Computer Architecture
Dr. Guy Tel-Zur

האצרהה תרטמ
ןיב הדרפה אוהו יזכרמ ןכת ןורקע לע דומענ וז הרצק תגצמב
.רקבל םינותנה לולסמ
:תגצמה יאשונ
םינותנ לולסמלו רקבל הקולחה .א
םינותנה לולסמ לש יגול םישרת .הנושאר המגוד תייעב .ב
תמכסמ םיבצמ תלבט ןכו רקבל FSM םישרתו
N! בושיח רובע ל"נכ .היינש המגוד תייעב .ג

This presentation is based on:
MIT Open course ware "Computation Structures"

by Dr. Christopher J. Terman.
References:

Chris Terman. 6.004 Computation
Structures. Spring 2017. Massachusetts
 MIT Open course ware
Institute of Technology: MIT
OpenCourseWare, https://ocw.mit.edu.
 MIT6.004 2020 License: Creative Commons BY-NC-SA.
 Slides by Prof. Shmuel Wimer Technion/BIU
In particular we will discuss material from:
https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-004-computation-
structures-spring-2017/c9/c9s1/#1
See 9.2.1, 9.2.2 @ MIT open course ware site

םינותנ לולסמו רקבל הקולח
control
external status data in
DATA
CONTROLLER
PATH
external control data out
status
clk
:םינותנ לולסמ •
דבעמ ,םינותנ ןסחאמ – דיקפת –
םיררוב ,ALU ,םכסמ ,םירטסיגר – םיינייפוא םיביכר •
:רקב •
םינותנה לולסמ עצבי המ עבוק – דיקפת –
.רטסיגרו ROM י"ע שומימ לשמל ,תיללכ תיתרדס תכרעמ - שומימ –
סוטטסו הרקב תותוא :םיקלחה ןיב רשק •
תויתרדס תוכרעמ ללכ ךרדב םה םיקלחה ינש •
תויורשפא רפסמ שי – הדיחי אל הקולחה •

ןלהל ,םדוקה ףקשב ןורחאה ףיעסל סחייתהב
םייביטנרטלא םימישרת

טושפ םינותנ לולסמל םייטרדנטס םיביכר
D D
k
k
Register Counter
Enable Clock Load Clock
k k
k k
Q
Q
A B
ALU
function
f ALU
k

 ךרוא  תורדס םכסמ :ןונכת תמגוד
הרדסה
| תירוט הרדס לבקמה יגול לגעמ :שרדנ |     |     |     |     | •   |
| -------------------------------- | --- | --- | --- | --- | --- |
..., 0, 0, n, x , x , ..., x , m, y , y , ..., y , 0, 0, ...
| 1   | 2     | n       | 1 2                | m   |     |
| --- | ----- | ------- | ------------------ | --- | --- |
|    | x ,  | y , ... |   םימוכסה תא בשחמו |     | •   |
|     | i     | i       |                    |     |     |
| n   | m     |         |                    |     |     |
 :ןונכתה יבלש •
 םייטרדנטס םיביכר תרזעב םינותנ לולסמ ןונכת .1
 )הנומ ,רטסיגר ,םכסמ(
 לולסמ לש תושירד – סוטטסו הרקב יווק תרדגה .2
רקבהמ םינותנה
 ,רטסיגר( םייטרדנטס םיביכר תרזעב רקב ןונכת .3
  )הנומ ,םכסמ

תורדס םכסמ :ארקמ
Control
Status
סנכנ טלק
Data
Input IN
טלק לבקתמש יוויח
Idle Input Start Input
L
R
L A,L
C R
Down
L
Reg
Input C Counter
הרדסה המייתסהש יוויח האצותה
Input
One
One One OUT
A B
Done Sum
L One A+B,L
ALU
C R
ALU FUNCTION
םנשי ןאכ (A, A+B)
One inverters
רקב םינותנ לולסמ

תורדס םכסמ :ארקמ
Control
Status
הרדס םותב דימ םא
Data
הרדס הליחתמ תחא
Input IN
תפסונ
Idle Input Start Input
L
R
L A,L
C R
Down
L
Reg
Input C Counter
Input
One
One One OUT
A B
Done Sum
L One A+B,L
ALU
C R
ALU FUNCTION
םנשי ןאכ (A, A+B)
One inverters
ןושארה רפסמה םא
רקב םינותנ לולסמ
זא דיחי אוה סנכנש
ונמייס

םירפסמ 3 תרדס םוכיסל אמגוד
Cycle No.    0            1              2             3              4             5             6
Clock
| IN  | 0   | 3   | 10  | 20  |     | 25  | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Input
| State |     | Idle | Start | Sum | Sum |     | Done | Idle |
| ----- | --- | ---- | ----- | --- | --- | --- | ---- | ---- |
L
C
| ALU func. |     | ?   | A   | A+B | A+B |     | ?   | ?   |
| --------- | --- | --- | --- | --- | --- | --- | --- | --- |
L
R
| ALU out |     | ?   | 10  | 30  |     | 55  | ?   | ?   |
| ------- | --- | --- | --- | --- | --- | --- | --- | --- |
| Reg     | ?   | ?   | ?   | 10  |     | 30  | 55  | 55  |
| Counter | 0   | 0   | 3   | 2   |     | 1   | 0   | 0   |
One

םיבצמה תלבט
| S        |       | Status |     | Control |      | S’    | Out       |
| -------- | ----- | ------ | --- | ------- | ---- | ----- | --------- |
| Current  | input | one    | L   | L       | ALU  | Next  | Register  |
|          |       |        | c   | R       |      |       |           |
| state    |       |        |     |         | Func | state | output    |
| IDLE     | 0     | x      | 1   | 0       | -    | IDLE  | x         |
| IDLE     | 1     | x      | 1   | 0       | -    | START | x         |
| START    | x     | 0      | 0   | 1       | A    | SUM   | A+B       |
| START    | x     | 1      | 0   | 1       | A    | DONE  | A         |
| SUM      | x     | 0      | 0   | 1       | A+B  | SUM   | A+B       |
| SUM      | x     | 1      | 0   | 1       | A+B  | DONE  | A+B       |
| DONE     | 0     | x      | 1   | 0       | -    | IDLE  | A+B       |
| DONE     | 1     | x      | 1   | 0       | -    | START | A+B       |

?הליעי םינותנ לולסמו רקבל הקולחה עודמ
תוכרעמ יתשל לודג םיבצמ רפסמ םע תיתרדס תכרעמ תדרפה - ןורקיעה
:תויתרדיס
)םיבצמה בור( לודג םיבצמ רפסמ )DP=DataPath) תחאב–
FSM-ל םייתרוסמ םילכב וניא ןונכתה
ןטק םיבצמה רפסמ (רקב) תרחאב–
ליגר FSM ןונכת עצבתמו
הנוכמב שי םיבצמ המכ ,םיבצמ k רקבבו םיבצמ n םינותנה לולסמב םא •
?קוריפ אלל
13
?)שי םיבצמ המכ( ןונכתה תויכוביס המ ,םיפולפ-פילפ K שי FSM-ב םא •

Credit: Brock J. LaMeres, "INTRODUCTION TO LOGIC CIRCUITS & LOGIC DESIGN WITH VERILOG"

םייפוסה םיבצמה תונוכמ יגוס 2 ןיב םילדבהה תודוא טושפ רבסה
טלק טלפ / טלק :Moore תנוכמ
טלקל רשק ילב ,ולש טלפה המ שארמ "עדוי" בצמ לכ ,רמולכ .הנוכמה תאצמנ ובש יחכונה בצמב קר יולת )output( טלפה
.עגרה לביקש
.טלקב יולת ןכ םיבצמ ןיב רבעמה
.1 היהי דימת טלפה ,וב תאצמנ הנוכמה דוע לכו S1 ארקנש בצמ שיש חיננ: הטושפ המגוד 🟢
.1 ראשנ טלפה ,S1 תא תבזוע אל איה דוע לכ ,לבקת איה טלק הזיא הנשמ אל
:Mealy תנוכמ
הנוש טלפ איצוהל הלוכי איה ,בצמ ותואב הנוכמה םא וליפא ,רמולכ .יחכונה טלקב םגו יחכונה בצמב םג יולת )output( טלפה
.תלבקמ איהש טלקה יפל
Mealy Moore
ןייפאמ
1 טלק תלבקמ איה םאו ,1 טלפ האיצומ איה 0 טלק תלבקמ איה םא לבא ,S1 בצמב הנוכמהש חיננ ה🟢טושפ המגוד 🟢
!בצמ ותואב איהש וליפא — 0 טלפ האיצומ איה
יחכונ טלקו יחכונ בצמ יחכונה בצמב קר ...ב יולת טלפה
)טלקל ידימ טלפ( רתוי הריהמ )בצמה יוניש לשב( הריהמ תוחפ טלקל הבוגת
ינוכסח םימעפל ,רתוי שימג רתוי טושפ ןכת

ינש ןיב האוושה
.םילדומה
הז לע בכעתהל אל
םיבצמה רפסמ
תשרדנה הרמוחה תומכ
רומ תנוכמ אוה הנומ
ןןווננככתתהה תתווללקק

FSM Example: Smiling Snail
(H&H Ch. 3 and Mutlu L07, 2022)
https://safari.ethz.ch/digitaltechnik/spring2022/lib/exe/fetch.php?media=digitaldesign-comparch-2022-lecture7-hdl-verilog-afterlecture.pdf
 A snail crawls down a paper tape with 1’s and 0’s on it
 The snail smiles whenever the last four digits it has crawled
over are 1101
 Design Moore and Mealy FSMs of the snail’s brain
Moore
לע אוה טלקה
.םיציחה
רפסמה אוה אצומה
םילוגיעה ךותב
Mealy
:םיציחה לע
input/output
טלקב יולת אצומה ןכל
18
בצמבו

D flip flop תרוכזת

האצותה תא ליכמ a
הטמ יפלכ הנומ b

יטנוולר Z
ןאכ קר
ריבעהל ידכ
תא
תכרעמה
בצמל
”2“

In: 2^3 = 8
Out: 2 + 2 + 2 =6
Total ROM size: 48 bits
לש גוזימ
תודומעה
םדוקה ףקשהמ

המגדה
The Snail's FSM

The Snail smiles if he detects
the sequence: 01
• Reference: H&H Chapter 3, Example 3.7

The Snail's truth tables

Moore's FSM implementation in
Verilog

Cyclone-IV FPGA dev. board

The happy Snail likes “1101”

Code development in Quartus

Pins assignment

Flash the code to the device

Click for the video
Click here

Watch the video on
Youtube:
https://youtu.be/K3Eri9pF
CKQ

Harris & Harris - The Snail Challenge
Exercise 3.25 Alyssa P. Hacker’s snail from Section 3.4.3 has a daughter with a
Mealy machine FSM brain. The daughter snail smiles whenever she slides over the
pattern 1101 or the pattern 1110. Sketch the state transition diagram for this
happy snail using as few states as possible. Choose state encodings and write a
combined state transition and output table using your encodings. Write the next
state and output equations and sketch your FSM schematic.

Implementation on Tang Nano 9k
FPGA
ץוחמ תצק הבישח :פוקסה תבחרה
תיסאלקה FSM -ה תספוקל
)Moore תנוכמב רבודמ(
This time we use a shift register that holds the a
‘pattern’ which is the last 4 values the snail traversed.
When the pattern is ‘1101’ the LED lit.
The Verilog code is in the next slide.

module smiling_snail( always @(posedge clk) begin
input clk, // Detect button presses
input btn0, // 0 input if (btn0 && !btn0_prev) begin
input btn1, // 1 input pattern <= {pattern[2:0], 1'b0}; // ןימימ 0 הפיסומ 0 םע הציחל
output reg LED0, // 0 pressed end else if (btn1 && !btn1_prev) begin
output reg LED1, // 1 pressed pattern <= {pattern[2:0], 1'b1}; // ןימימ 1 הפיסומ 1 לע הציחל
output reg LED3 // snail smiles (1101 reached) end
); // Check for 1101 pattern
reg [3:0] pattern; LED3 <= ~(pattern == 4'b1101);
reg btn0_prev, btn1_prev; // Update button states
initial begin btn0_prev <= btn0;
pattern = 4'b0000; // pattern is a shift register btn1_prev <= btn1;
LED0 = 1'b0; // Update LED0 and LED1
LED1 = 1'b0; LED0 <= btn0;
LED3 = 1'b0; LED1 <= btn1;
btn0_prev = 1'b0; end
btn1_prev = 1'b0; endmodule a short video about that is in
end the next slide...

Similar code on an IceBreaker FPGA
Folder:
/home/telzur/science/Teaching/CPU/lectures/04/code/Harris_Snail/ICE40
Files:
smiling_snail.v, smiling_snail.pcf, makeit.sh
https://www.crowdsupply.com/1bitsquared/icebreaker-fpga

וז תגצמ ןאכ דע
H&H -ב 3 .4 ףיעס ואר FSM תודוא תפסונ האירקל