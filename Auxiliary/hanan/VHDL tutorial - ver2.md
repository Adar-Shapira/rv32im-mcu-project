| VHDL      | Tutorial           |           |               |     |
| --------- | ------------------ | --------- | ------------- | --- |
| Presenter | :                  | Raj Singh |               |     |
|           | IC Design          | Group     |               |     |
|           | CEERI,             | Pilani    | (cid:150) 333 | 031 |
|           | Rajasthan,         | India     |               |     |
| Tel :     | 01596-242359       |           |               |     |
| Fax :     | 01596-242294       |           |               |     |
| E-Mail :  | raj@ceeri.ernet.in |           |               |     |

VHDL Tutorial : Introduction
Introduction
1.
Overview
2.
Constructs
3.
Usage
4.
Examples
5.
(cid:13)c CEERI, Pilani IC Design Group 1

| VHDL Tutorial | : Introduction |     |     |     |     |
| ------------- | -------------- | --- | --- | --- | --- |
VHDL
|     |     |     | History | of  |     |
| --- | --- | --- | ------- | --- | --- |
1981 : Department of Defense, USA launches the (cid:147)Very High Speed Inte-
| grated | Circuits(cid:148) | (VHSIC) | project. |     |     |
| ------ | ----------------- | ------- | -------- | --- | --- |
1983 : Request for Proposal (RFP) issued by US Air Force to develop a lan-
guage for hardware design description. The winner was a team composed
| of  | Intermetrics, | IBM and | TI. |     |     |
| --- | ------------- | ------- | --- | --- | --- |
VHDL
| 1985 | : version | 7.2 made | available. |     |     |
| ---- | --------- | -------- | ---------- | --- | --- |
1986 : Initial suite of support software released. IEEE starts effort of stan-
VHDL.
dardizing
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 2   |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial | : Introduction |     |          |     |         |     |
| ------------- | -------------- | --- | -------- | --- | ------- | --- |
|               |                |     | (cid:11) |     | (cid:8) |     |
VHDL
History of
|      |             |          | (cid:10)  |          | (cid:9) |     |
| ---- | ----------- | -------- | --------- | -------- | ------- | --- |
| 1987 | : IEEE-1076 | Standard | released, | VHDL-87. |         |     |
VHDL-93.
| 1993             | : Revised | IEEE-1076    | Standard  | released, |            |     |
| ---------------- | --------- | ------------ | --------- | --------- | ---------- | --- |
| 2001             | : Revised | IEEE-1076    | Standard  | released, | VHDL-2001. |     |
| 2002             | : Work    | on VHDL-200x | started.  |           |            |     |
| (cid:13)c CEERI, | Pilani    |              | IC Design | Group     |            | 3   |

VHDL Tutorial : Overview
Introduction
1.
Overview
2.
Constructs
3.
Usage
4.
Examples
5.
(cid:13)c CEERI, Pilani IC Design Group 4

| VHDL Tutorial | :   | Overview |     |     |     |     |     |     |
| ------------- | --- | -------- | --- | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Model |     | of a | Hardware | in  |     |
| --- | --- | --- | ----- | --- | ---- | -------- | --- | --- |
A hardware model in VHDL is described in two parts, the entity declaration part
| and the | associated |     | architecture |     | body | part. |     |     |
| ------- | ---------- | --- | ------------ | --- | ---- | ----- | --- | --- |
ENTITY
|     |     |     |     | BODY 1 |     | BODY 2 | BODY N |     |
| --- | --- | --- | --- | ------ | --- | ------ | ------ | --- |
The entity declaration gives a name to the model being developed and also
declares its external interface signals (called ports) : their names, modes (in,
| out, inout,      |        | buffer) | and | their | types. |              |     |     |
| ---------------- | ------ | ------- | --- | ----- | ------ | ------------ | --- | --- |
| (cid:13)c CEERI, | Pilani |         |     |       | IC     | Design Group |     | 5   |

| VHDL Tutorial | : Overview |     |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- | --- |
(cid:11) (cid:8)
VHDL
|     |     |     | Model | of a Hardware |     | in  |     |
| --- | --- | --- | ----- | ------------- | --- | --- | --- |
(cid:10) (cid:9)
The architecture body de(cid:2)nes the internal details of the model (cid:151) including any
internal signals and one or more concurrent statements that together model
the hardware.
Multiple architectures are allowed to be de(cid:2)ned for one entity (cid:151) representing
the design’s description at different levels of abstraction or multiple implemen-
tations of the same design speci(cid:2)cations (cid:151) although only one of them can be
| selected | at any | time for | the purpose | of  | simulation. |     |     |
| -------- | ------ | -------- | ----------- | --- | ----------- | --- | --- |
As mentioned earlier, there are various ways of describing the internal behav-
iour, and one or more coding styles from the behavioural, structural, data-(cid:3)ow
| styles           | may be | chosen.   |                      |           |       |     |     |
| ---------------- | ------ | --------- | -------------------- | --------- | ----- | --- | --- |
| Please           | note   | that VHDL | is case-insensitive. |           |       |     |     |
| (cid:13)c CEERI, | Pilani |           |                      | IC Design | Group |     | 6   |

| VHDL    | Tutorial |     | : Overview |     |     |     |     |     |     |     |
| ------- | -------- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- |
| Example |          |     | :          |     |     |     |     |     |     |     |
I1
O
I2
Delay = 2 ns
| entity       |      | AND2 |       | GATE | is       |     |         |           |     |     |
| ------------ | ---- | ---- | ----- | ---- | -------- | --- | ------- | --------- | --- | --- |
|              | port | ( I1 | ,     | I2   | : in BIT | ;   | O       | : out BIT | ) ; |     |
| end          | AND2 |      | GATE; |      |          |     |         |           |     |     |
| architecture |      |      |       | BEH  | MODEL    |     | of AND2 | GATE      | is  |     |
begin
| (cid:0)(cid:0) | Sensitivity |     |     |     | l i s t is |     | I1 and | I2  |     |     |
| -------------- | ----------- | --- | --- | --- | ---------- | --- | ------ | --- | --- | --- |
|                | process(    |     | I1  | ,   | I2 )       |     |        |     |     |     |
begin
<
|                  | O   | =       | I1  | and | I2 after |     | 2   | ns ;      |       |     |
| ---------------- | --- | ------- | --- | --- | -------- | --- | --- | --------- | ----- | --- |
|                  | end | process |     | ;   |          |     |     |           |       |     |
| end              | BEH | MODEL;  |     |     |          |     |     |           |       |     |
| (cid:13)c CEERI, |     | Pilani  |     |     |          |     |     | IC Design | Group | 7   |

| VHDL Tutorial | : Overview |     |        |       |         |     |     |
| ------------- | ---------- | --- | ------ | ----- | ------- | --- | --- |
|               |            |     | Design | Units | in VHDL |     |     |
entity declaration and architecture body are design units in VHDL.
VHDL
A design unit is the smallest code segment that can be independently
| compiled. | In VHDL | parlance, | compilation |     | is called | analysis. |     |
| --------- | ------- | --------- | ----------- | --- | --------- | --------- | --- |
The entity declaration is a primary design unit which can be analyzed indepen-
dently.
The architecture body is a secondary design unit (cid:151) it can be analyzed only if
its corresponding primary design unit (i.e. the entity declaration) has already
| been | analyzed. |     |     |     |     |     |     |
| ---- | --------- | --- | --- | --- | --- | --- | --- |
VHDL
| The other        | design | units in | are | :      |       |     |     |
| ---------------- | ------ | -------- | --- | ------ | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |          | IC  | Design | Group |     | 8   |

| VHDL Tutorial | : Overview |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
(cid:15)
package declaration permits packaging a set of declarations (of types, sig-
nals, functions) which can be analyzed (compiled) once in a design library
and invoked by other design units as required by one or more users. (pri-
| mary | design | unit) |     |     |     |     |
| ---- | ------ | ----- | --- | --- | --- | --- |
(cid:15) package body contains the bodies of de(cid:2)nitions corresponding to the dec-
larations in the corresponding package declaration. (secondary design
unit)
(cid:15) con(cid:2)guration declarations are used to supply the entity-architecture names
(bindings) for component instances in structural descriptions. (primary de-
| sign | unit) |     |     |     |     |     |
| ---- | ----- | --- | --- | --- | --- | --- |
Thus, a VHDL design description (cid:2)le may contain one or more design units
and references to design units or items in packages that have already been
| compiled         | into one | or more | design | libraries. |       |     |
| ---------------- | -------- | ------- | ------ | ---------- | ----- | --- |
| (cid:13)c CEERI, | Pilani   |         |        | IC Design  | Group | 9   |

| VHDL Tutorial | : Overview |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
VHDL
| A                | design      | (cid:2)le looks | like the | following | :     |     |
| ---------------- | ----------- | --------------- | -------- | --------- | ----- | --- |
| Reference        | Clauses     |                 |          |           |       |     |
| Design           | Unit        |                 |          |           |       |     |
| Design           | Unit        |                 |          |           |       |     |
| Reference        | Clauses     |                 |          |           |       |     |
| Design           | Unit        |                 |          |           |       |     |
| Reference        | Clauses     |                 |          |           |       |     |
| Design           | Unit        |                 |          |           |       |     |
| Design           | Unit        |                 |          |           |       |     |
| Or, as           | follows     | :               |          |           |       |     |
| Package          | Declaration |                 |          |           |       |     |
| Package          | Body        |                 |          |           |       |     |
| Package          | Declaration |                 |          |           |       |     |
| Package          | Body        |                 |          |           |       |     |
| Reference        | Clauses     |                 |          |           |       |     |
| Entity           | Declaration |                 |          |           |       |     |
| Architecture     |             | Body            |          |           |       |     |
| Entity           | Declaration |                 |          |           |       |     |
| Architecture     |             | Body            |          |           |       |     |
| Configuration    |             | Declaration     |          |           |       |     |
| (cid:13)c CEERI, | Pilani      |                 |          | IC Design | Group | 10  |

| VHDL | Tutorial : | Overview |        |          |     |       |      |     |
| ---- | ---------- | -------- | ------ | -------- | --- | ----- | ---- | --- |
|      |            |          | System | Modeling |     | Using | VHDL |     |
How does VHDL address the hardware modeling issues discussed earlier ?
(cid:15)
|     | Support | for Concurrency |     | :   |     |     |     |     |
| --- | ------- | --------------- | --- | --- | --- | --- | --- | --- |
VHDL provides a rich set of concurrent statements to model the concur-
rency in digital hardware. The execution of a concurrent statement is trig-
gered by event(s) on one or more of its input signals to which it is sensitive
|     | (called | sensitivity | channels). |     |     |     |     |     |
| --- | ------- | ----------- | ---------- | --- | --- | --- | --- | --- |
The language semantics require that simulation time should not be ad-
vanced until all the concurrent statements whose sensitivity channels have
|                  | had events | at current | time | have | been   | processed. |     |     |
| ---------------- | ---------- | ---------- | ---- | ---- | ------ | ---------- | --- | --- |
| (cid:13)c CEERI, | Pilani     |            |      | IC   | Design | Group      |     | 11  |

| VHDL Tutorial | : Overview |     |       |       |               |     |
| ------------- | ---------- | --- | ----- | ----- | ------------- | --- |
|               |            |     | Delta | Delay | in Simulation |     |
To support zero-delay simulation consistent with cause-effect sequentiality.
To take care of stability of sequential (feedback) circuit elements.
| Current          | simulation | time | is not | advanced. |       |     |
| ---------------- | ---------- | ---- | ------ | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani     |      |        | IC Design | Group | 12  |

| VHDL Tutorial | : Overview |     |     |     |
| ------------- | ---------- | --- | --- | --- |
Start Simulation
Increment Time
Update Signals Evaluate Models
Events
End Simulation
| (cid:13)c CEERI, | Pilani | IC Design | Group | 13  |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Overview |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- |
(cid:15) VHDL provides the following different concurrent statements :
|     | (cid:150) process | statement | for behavioural | descriptions. |     |
| --- | ----------------- | --------- | --------------- | ------------- | --- |
block statement for structuring complex descriptions and to capture
(cid:150)
hierarchy.
|     | (cid:150) concurrent | assertion | statement | for checks. |     |
| --- | -------------------- | --------- | --------- | ----------- | --- |
(cid:150) concurrent procedure call for data-(cid:3)ow description.
(cid:150) concurrent signal assignment statement for data-(cid:3)ow descriptions.
(cid:150) component instantiation statement for structural descriptions.
|                  | (cid:150) generate | statement | for structural | descriptions. |     |
| ---------------- | ------------------ | --------- | -------------- | ------------- | --- |
| (cid:13)c CEERI, | Pilani             |           | IC Design      | Group         | 14  |

| VHDL Tutorial    | : Overview |                 |     |        |     |     |     |     |
| ---------------- | ---------- | --------------- | --- | ------ | --- | --- | --- | --- |
| (cid:15) Support |            | for abstraction |     | levels | :   |     |     |     |
VHDL
supports design abstractions from behavioural level to gate level. It
supports a variety of data types and operations on them to suit hardware
| modeling         |     | at          | different | levels    | of abstraction. |     |     |     |
| ---------------- | --- | ----------- | --------- | --------- | --------------- | --- | --- | --- |
| (cid:15) Support |     | for complex |           | behaviour | / functionality |     | :   |     |
VHDL provides a rich set of procedural (sequential) statements (typical of
C)
high-level programming languages like to describe the behaviour / func-
| tionality |     | of the | hardware. |     |     |     |     |     |
| --------- | --- | ------ | --------- | --- | --- | --- | --- | --- |
Procedural / algorithmic constructs for program structuring, data structur-
ing and program control are available for describing the behaviour of the
| hardware         |        | procedurally. |     |     |           |       |     |     |
| ---------------- | ------ | ------------- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |               |     |     | IC Design | Group |     | 15  |

| VHDL | Tutorial | : Overview |     |     |     |     |     |     |     |
| ---- | -------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
(cid:15) Constructs are available for modeling delayed change(s) of outputs in re-
|     | sponse | to changes |     | in the | inputs | of  | digital | hardware. |     |
| --- | ------ | ---------- | --- | ------ | ------ | --- | ------- | --------- | --- |
(cid:15) Constructs are available for identifying the direction of (cid:3)ow of information
|     | at the | interface | points | of  | a digital | system. |     |     |     |
| --- | ------ | --------- | ------ | --- | --------- | ------- | --- | --- | --- |
(cid:15) For passing data values among different concurrent statements (each con-
current statement is used to model a part of the hardware), VHDL provides
signals. Language semantics require that the current value and predicted
|     | waveform | elements |     | of signals |     | be maintained. |     |     |     |
| --- | -------- | -------- | --- | ---------- | --- | -------------- | --- | --- | --- |
Time evolution of signal values (for all the signals in a model) represents
the time evolution of the state of the digital system in response to stimuli.
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group |     | 16  |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- | --- |

VHDL Tutorial : Constructs
Introduction
1.
Overview
2.
Constructs
3.
Usage
4.
Examples
5.
(cid:13)c CEERI, Pilani IC Design Group 17

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
VHDL
|     |     | Behavioural | Modeling |     | in  |     |
| --- | --- | ----------- | -------- | --- | --- | --- |
VHDL process
The main construct for behavioural modeling of hardware is the
statement (which is one of the concurrent statements of the language). The
process statement has an associated body of sequential statements which
are executed to compute and schedule output changes every time any input
signal on the sensitivity channels of the process statement changes.
| Example | :   |     |     |     |     |     |
| ------- | --- | --- | --- | --- | --- | --- |
IN1
IN2
ZOUT
MUX_4
IN3
IN4
|                  |        |     | S1        | S0    |     |     |
| ---------------- | ------ | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |     | IC Design | Group |     | 18  |

| VHDL   | Tutorial  |       | : Constructs |      |      |       |          |     |      |      |     |
| ------ | --------- | ----- | ------------ | ---- | ---- | ----- | -------- | --- | ---- | ---- | --- |
| entity |           | MUX_4 |              | is   |      |       |          |     |      |      |     |
|        | port(IN1, |       |              | IN2, | IN3, |       | IN4, S1, | S0  | : in | BIT; |     |
|        |           | ZOUT  |              | :    | out  | BIT); |          |     |      |      |     |
end MUX_4;
| architecture |     |     |     | BEH | of  | MUX_4 | is  |     |     |     |     |
| ------------ | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- |
begin
|     | process(IN1, |     |     |     | IN2, | IN3, | IN4, | S0, | S1) |     |     |
| --- | ------------ | --- | --- | --- | ---- | ---- | ---- | --- | --- | --- | --- |
begin
|     | if    | (S1  |     | = ’0’ | and   | S0  | = ’0’) | then |      |     |     |
| --- | ----- | ---- | --- | ----- | ----- | --- | ------ | ---- | ---- | --- | --- |
|     |       | ZOUT |     | <=    | IN1;  |     |        |      |      |     |     |
|     | elsif |      | (S1 |       | = ’0’ | and | S0 =   | ’1’) | then |     |     |
|     |       | ZOUT |     | <=    | IN2;  |     |        |      |      |     |     |
|     | elsif |      | (S1 |       | = ’1’ | and | S0 =   | ’0’) | then |     |     |
|     |       | ZOUT |     | <=    | IN3;  |     |        |      |      |     |     |
else
|     |     | ZOUT     |     | <=  | IN4; |     |     |     |     |     |     |
| --- | --- | -------- | --- | --- | ---- | --- | --- | --- | --- | --- | --- |
|     | end |          | if; |     |      |     |     |     |     |     |     |
|     | end | process; |     |     |      |     |     |     |     |     |     |
end BEH;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     |     |     | IC Design | Group | 19  |
| ---------------- | --- | ------ | --- | --- | --- | --- | --- | --- | --------- | ----- | --- |

VHDL Tutorial : Constructs
|     |     |     | Types, | Operators |     |     | and Objects |     | in VHDL |     |
| --- | --- | --- | ------ | --------- | --- | --- | ----------- | --- | ------- | --- |
Every modeling language models its subject using certain value sets, opera-
tions on those value sets and de(cid:2)ning storage locations to hold the values.
| VHDL | is a strongly-typed |     |     | language. |     |     |     |     |     |     |
| ---- | ------------------- | --- | --- | --------- | --- | --- | --- | --- | --- | --- |
(cid:15) In VHDL, distinct value sets are de(cid:2)ned through different type declarations.
|     | The language |     | also | has | prede(cid:2)ned |     | types. |     |     |     |
| --- | ------------ | --- | ---- | --- | --------------- | --- | ------ | --- | --- | --- |
The set of prede(cid:2)ned types (and subtypes) are contained in the VHDL pack-
STANDARD.
|                  | age      |          | They       | are       | :   |                 |       |       |     |     |
| ---------------- | -------- | -------- | ---------- | --------- | --- | --------------- | ----- | ----- | --- | --- |
|                  | Boolean, | bit,     | character, |           |     | severity_level, |       |       |     |     |
|                  | integer, | natural, |            | positive, |     |                 | real, | time, |     |     |
| (cid:13)c CEERI, | Pilani   |          |            |           |     | IC Design       | Group |       |     | 20  |

| VHDL Tutorial   | : Constructs |     |                   |     |             |     |     |     |
| --------------- | ------------ | --- | ----------------- | --- | ----------- | --- | --- | --- |
| delay_length,   |              |     | string,           |     | bit_vector, |     |     |     |
| file_open_kind, |              |     | file_open_status. |     |             |     |     |     |
STANDARD
| A   | listing of | the | package |     |     | is given | in Annexure-I. |     |
| --- | ---------- | --- | ------- | --- | --- | -------- | -------------- | --- |
(cid:15) Different operations on values of speci(cid:2)c types are de(cid:2)ned with the help
| of  | function | declaration |     | and | de(cid:2)nitions. |     |     |     |
| --- | -------- | ----------- | --- | --- | ----------------- | --- | --- | --- |
The language also provides a set of pre-de(cid:2)ned operators for the speci(cid:2)c
| pre-de(cid:2)ned |        | types. |     |     |           |       |     |     |
| ---------------- | ------ | ------ | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |        |     |     | IC Design | Group |     | 21  |

| VHDL Tutorial | : Constructs |     |     |     |
| ------------- | ------------ | --- | --- | --- |
(cid:15) VHDL creates four distinct classes of objects for storing values it manipu-
lates. This is done through object declarations. The four object classes
| are | :   |     |     |     |
| --- | --- | --- | --- | --- |
1. Signal.
2. Variable.
3. Constant.
4. File.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 22  |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Constructs |          |     |     |     |     |     |         |     |
| ------------- | ------------ | -------- | --- | --- | --- | --- | --- | ------- | --- |
|               |              | (cid:11) |     |     |     |     |     | (cid:8) |     |
VHDL
|     |     |          | Types, | Operators |     | and Objects | in  |         |     |
| --- | --- | -------- | ------ | --------- | --- | ----------- | --- | ------- | --- |
|     |     | (cid:10) |        |           |     |             |     | (cid:9) |     |
(cid:15) VHDL provides unlimited number of data types for characterizing the values
| held             | by signal,  |        | variable    |     | and constant. |            |            |     |     |
| ---------------- | ----------- | ------ | ----------- | --- | ------------- | ---------- | ---------- | --- | --- |
| Data             | types       | are    | categorized |     | into          | four major | categories | :   |     |
| 1.               | Scalar      | types. |             |     |               |            |            |     |     |
| 2.               | Composite   |        | types.      |     |               |            |            |     |     |
| 3.               | Access      | types. |             |     |               |            |            |     |     |
| 4.               | File types. |        |             |     |               |            |            |     |     |
| (cid:13)c CEERI, | Pilani      |        |             |     | IC Design     | Group      |            |     | 23  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Types | in  | : Scalars |     |
| --- | --- | --- | ----- | --- | --------- | --- |
Values belonging to these types are ordered along a scale. Also, they are
basic values that cannot be decomposed further into simpler values. These
| are of | four different | kinds | :   |     |     |     |
| ------ | -------------- | ----- | --- | --- | --- | --- |
1. Enumeration.
2. Integer.
3. Floating point.
4. Physical.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 24  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial    | :                 | Constructs          |            |           |             |         |       |        |        |           |     |     |
| ---------------- | ----------------- | ------------------- | ---------- | --------- | ----------- | ------- | ----- | ------ | ------ | --------- | --- | --- |
| Example          | of                | enumeration         |            |           | type.       |         |       |        |        |           |     |     |
| type             | THREE_LEVEL_LOGIC |                     |            |           |             | is      | (’X’, | ’0’,   |        | ’1’);     |     |     |
| signal           | A :               | THREE_LEVEL_LOGIC;  |            |           |             |         |       |        |        |           |     |     |
| type             | COLOUR            | is                  | (green,    |           |             | yellow, |       | red);  |        |           |     |     |
| variable         | LIGHT             |                     | :          | COLOUR;   |             |         |       |        |        |           |     |     |
| Example          | of                | integer             |            | type.     |             |         |       |        |        |           |     |     |
| type             | WORD_LENGTH       |                     |            | is        | range       |         | 31    | downto | 0;     |           |     |     |
| subtype          | DATA_WORD         |                     |            | is        | WORD_LENGTH |         |       | range  |        | 15 downto | 0;  |     |
| signal           | DATA              | :                   | DATA_WORD; |           |             |         |       |        |        |           |     |     |
| variable         | INDEX             |                     | :          | integer;  |             |         |       |        |        |           |     |     |
| Example          | of                | (cid:3)oating-point |            |           | type.       |         |       |        |        |           |     |     |
| type             | REAL_DATA         |                     | is         | range     |             | 0.0     | to    | 20.0;  |        |           |     |     |
| variable         | WIDTH             |                     | :          | REAL_DATA |             |         | range | 1.0    |        | to 15.0;  |     |     |
| variable         | TEMPERATURE       |                     |            |           | :           | real;   |       |        |        |           |     |     |
| (cid:13)c CEERI, | Pilani            |                     |            |           |             |         |       | IC     | Design | Group     |     | 25  |

| VHDL Tutorial | : Constructs |             |               |     |     |
| ------------- | ------------ | ----------- | ------------- | --- | --- |
| Example       | of physical  | type.       |               |     |     |
| type time     | is range     | -2147483647 | to 2147483647 |     |     |
units
fs;
| ps               | = 1000 fs; |     |           |       |     |
| ---------------- | ---------- | --- | --------- | ----- | --- |
| ns               | = 1000 ps; |     |           |       |     |
| us               | = 1000 ns; |     |           |       |     |
| ms               | = 1000 us; |     |           |       |     |
| sec              | = 1000     | ms; |           |       |     |
| min              | = 60 sec;  |     |           |       |     |
| hr               | = 60 min;  |     |           |       |     |
| end              | units;     |     |           |       |     |
| (cid:13)c CEERI, | Pilani     |     | IC Design | Group | 26  |

| VHDL Tutorial | :   | Constructs |     |     |     |     |
| ------------- | --- | ---------- | --- | --- | --- | --- |
VHDL
|     |     |     | Types | in  | : Composites |     |
| --- | --- | --- | ----- | --- | ------------ | --- |
A composite type represents a collection of values. There are two different
| composite |     | types : |     |     |     |     |
| --------- | --- | ------- | --- | --- | --- | --- |
1. Array.
2. Record.
Arrays are homogeneous composite types i.e. the elements of an array are all
| of the | same | type. |     |     |     |     |
| ------ | ---- | ----- | --- | --- | --- | --- |
Records are heterogeneous composite types i.e. the elements of a record can
| be of            | different | types. |     |           |       |     |
| ---------------- | --------- | ------ | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani    |        |     | IC Design | Group | 27  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- | --- |
Example of constrained one-dimensional array type. Here the number of elements in the array
is explicitly speci(cid:2)ed in the type declaration by specifying the constraints on the range of the
index.
| type ADDRESS_WORD |     |     | is array(31 |     | downto | 0) of | BIT; |     |
| ----------------- | --- | --- | ----------- | --- | ------ | ----- | ---- | --- |
Example of declaring a variable (object) of the user-de(cid:2)ned type ADDRESS WORD.
| variable        | NEXT_ADDRESS  |                 | :      | ADDRESS_WORD; |               |            |     |     |
| --------------- | ------------- | --------------- | ------ | ------------- | ------------- | ---------- | --- | --- |
| Example         | of assignment |                 | to an  | entire        | array.        |            |     |     |
| NEXT_ADDRESS    |               | := X"FFFFFFFF"; |        |               |               |            |     |     |
| Example         | of assignment |                 | to one | element       | of            | the array. |     |     |
| NEXT_ADDRESS(0) |               | :=              | ’1’;   |               |               |            |     |     |
| Example         | of assignment |                 | to a   | slice         | of the array. |            |     |     |
| NEXT_ADDRESS(7  |               | downto          | 0)     | :=            | X"AA";        |            |     |     |
Example of unconstrained one-dimensional array type. Here no constraints are speci(cid:2)ed on
the range of the index in type declaration. Hence, the number of elements in the array is not
| speci(cid:2)ed   | in the | type declaration. |     |     |     |              |     |     |
| ---------------- | ------ | ----------------- | --- | --- | --- | ------------ | --- | --- |
| (cid:13)c CEERI, | Pilani |                   |     |     | IC  | Design Group |     | 28  |

| VHDL | Tutorial   | :   | Constructs |     |               |     |          |     |     |         |     |
| ---- | ---------- | --- | ---------- | --- | ------------- | --- | -------- | --- | --- | ------- | --- |
| type | BIT_vector |     |            | is  | array(natural |     | range<>) |     |     | of BIT; |     |
BIT vector.
Example of declaring a variable (object) of the pre-de(cid:2)ned type
| variable |     | ACCUMULATOR |     |     | : BIT_vector(15 |     |     | downto |     | 0); |     |
| -------- | --- | ----------- | --- | --- | --------------- | --- | --- | ------ | --- | --- | --- |
Please note that you must specify the constraints on the index of an unconstrained array type
when declaring an object of that type. In view of this, the following variable declaration is
| illegal  | :   |             |     |     |               |     |     |     |         |     |     |
| -------- | --- | ----------- | --- | --- | ------------- | --- | --- | --- | ------- | --- | --- |
| variable |     | ACCUMULATOR |     |     | : BIT_vector; |     |     | --  | illegal |     |     |
Example of an array of array : declaring one-dimensional array type whose elements are
| themselves       |           |              | of one-dimensional |     |                   | array    | type.      |        |       |     |     |
| ---------------- | --------- | ------------ | ------------------ | --- | ----------------- | -------- | ---------- | ------ | ----- | --- | --- |
| This             | is not    | the          | same               | as  | a two-dimensional |          |            | array. |       |     |     |
| type             | DATA_WORD |              |                    | is  | array(15          | downto   | 0)         | of     | BIT;  |     |     |
| type             | ROM       | is           | array(0            |     | to 127)           | of       | DATA_WORD; |        |       |     |     |
| Example          |           | of declaring |                    |     | a variable        | (object) | of         | ROM    | type. |     |     |
| variable         |           | CONTROL_ROM  |                    |     | : ROM;            |          |            |        |       |     |     |
| (cid:13)c CEERI, |           | Pilani       |                    |     |                   |          | IC         | Design | Group |     | 29  |

| VHDL Tutorial | :   | Constructs |     |     |     |     |     |     |     |
| ------------- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- |
Example of assignment to an element of CONTROL ROM which is itself an array of 16 elements
| of type        | BIT. |     |     |          |     |     |     |     |     |
| -------------- | ---- | --- | --- | -------- | --- | --- | --- | --- | --- |
| CONTROL_ROM(6) |      |     | :=  | X"AAAA"; |     |     |     |     |     |
Example of assignment to one single-bit of an element of CONTROL ROM.
| CONTROL_ROM(6)(9) |     |     |     | := ’1’; |     |     |     |     |     |
| ----------------- | --- | --- | --- | ------- | --- | --- | --- | --- | --- |
Example of assignment to a slice of an element of CONTROL ROM.
| CONTROL_ROM(0)(7 |                  |             | downto |                 | 0) :=         | X"FF"; |            |               |     |
| ---------------- | ---------------- | ----------- | ------ | --------------- | ------------- | ------ | ---------- | ------------- | --- |
| Example          | of               | constrained |        | two-dimensional |               |        | array      | type.         |     |
| type             | CHAR_SCREEN      |             | is     |                 |               |        |            |               |     |
|                  | array(1          |             | to     | 24,             | 1 to 80)      | of     | CHARACTER; |               |     |
| type             | ROW is           | range       |        | 1 to            | 24;           |        |            |               |     |
| type             | COLUMN           | is          | range  | 1               | to 80;        |        |            |               |     |
| type             | CHAR_SCREEN      |             | is     |                 |               |        |            |               |     |
|                  | array(ROW’range, |             |        |                 | COLUMN’range) |        |            | of CHARACTER; |     |
Example of declaring a variable (object) of the user-de(cid:2)ned type CHAR SCREEN.
| (cid:13)c CEERI, | Pilani |     |     |     |     |     | IC Design | Group | 30  |
| ---------------- | ------ | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Constructs  |                |         |             |     |     |
| ------------- | ------------- | -------------- | ------- | ----------- | --- | --- |
| variable      | CONSOLE       | : CHAR_SCREEN; |         |             |     |     |
| Example       | of assignment | to an          | element | of CONSOLE. |     |     |
| CONSOLE(7,4)  | :=            | ’C’;           |         |             |     |     |
Note that you can also de(cid:2)ne unconstrained two-dimensional array types. However, when
declaring an object (say variable) of that type, you must constrain the index range in each
dimension. You can de(cid:2)ne both constrained and unconstrained array types of more than two
| dimensions         | (in fact     | an arbitrary | number | of dimensions). |     |     |
| ------------------ | ------------ | ------------ | ------ | --------------- | --- | --- |
| Example            | of declaring | a record     | type.  |                 |     |     |
| type REGISTER_BANK |              | is           |        |                 |     |     |
record
| F0, | F1 : real;    |     |     |     |     |     |
| --- | ------------- | --- | --- | --- | --- | --- |
| R0, | R1 : integer; |     |     |     |     |     |
| end | record;       |     |     |     |     |     |
REGISTER BANK.
Example of declaring a variable (object) of the user-de(cid:2)ned type
| variable         | A_BANK        | : REGISTER_BANK; |         |            |       |     |
| ---------------- | ------------- | ---------------- | ------- | ---------- | ----- | --- |
| Example          | of assignment | to an            | element | of A BANK. |       |     |
| (cid:13)c CEERI, | Pilani        |                  |         | IC Design  | Group | 31  |

| VHDL Tutorial | : Constructs |     |     |     |
| ------------- | ------------ | --- | --- | --- |
| A_BANK.F0     | := 4.50;     |     |     |     |
Example of assignment to A BANK (the entire record object) using an aggregate.
| A_BANK | := (16.0,24.0,5,10); |     |     |     |
| ------ | -------------------- | --- | --- | --- |
Aggregates can also be used to assign to entire one-dimensional arrays, one-dimensional ar-
rays whose elements are themselves one-dimensionalarrays, two or more dimensional arrays.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 32  |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Constructs |     |          |     |          |     |
| ------------- | ------------ | --- | -------- | --- | -------- | --- |
|               |              |     | Subtypes |     | of Types |     |
A subtype is a type with constraints. The constraint speci(cid:2)es the subset of
values for the type. The type is called the base type of the subtype. An object
is said to belong to a subtype if it is of the base type and if it satis(cid:2)es the con-
straint. Subtype declarations are used to declare subtypes. An object can be
declared to belong to either a type or a subtype. The set of operations belong-
ing to a subtype is the same as that associated with its base type. Subtypes
are useful for range checking and for imposing additional constraints on types.
| Example    | :                        |                  |       |        |        |     |
| ---------- | ------------------------ | ---------------- | ----- | ------ | ------ | --- |
| subtype    | MY_INTEGER               | is integer       | range | 1      | to 64; |     |
| subtype    | MEM_ADDRESS              | is BIT_vector(31 |       | downto | 0);    |     |
| type DIGIT | is (‘0’,‘1’,‘2’,‘3’,‘4’, |                  |       |        |        |     |
‘5’,‘6’,‘7’,‘8’,‘9’);
| subtype          | MID_DIGIT | is DIGIT | range | ‘3’ to    | ‘6’;  |     |
| ---------------- | --------- | -------- | ----- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani    |          |       | IC Design | Group | 33  |

| VHDL Tutorial | : Constructs |          |           |       |         |          |          |             |     |
| ------------- | ------------ | -------- | --------- | ----- | ------- | -------- | -------- | ----------- | --- |
|               |              | (cid:11) |           |       |         |          | (cid:8)  |             |     |
|               |              | Types,   | Operators | and   | Objects | in VHDL  |          |             |     |
|               |              | (cid:10) |           |       |         |          | (cid:9)  |             |     |
|               |              | Values   | belonging | to an | access  | type are | pointers | to a dynam- |     |
| Access        | Types        | :        |           |       |         |          |          |             |     |
ically allocated object of some other type. We will not be discussing them
| any | further. |     |     |     |     |     |     |     |     |
| --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
File Types : Objects of (cid:2)le types represent (cid:2)les in the host environment. They
provide a mechanism by which a VHDL design communicates with the host
environment. The (cid:2)le type declarations and declaration of (cid:2)le objects will
| be               | covered | later. |     |           |       |     |     |     |     |
| ---------------- | ------- | ------ | --- | --------- | ----- | --- | --- | --- | --- |
| (cid:13)c CEERI, | Pilani  |        |     | IC Design | Group |     |     |     | 34  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
(cid:11) (cid:8)
VHDL
|     |     | Types, | Operators | and | Objects | in  |     |
| --- | --- | ------ | --------- | --- | ------- | --- | --- |
(cid:10) (cid:9)
Operators : The operators in VHDL are classi(cid:2)ed into seven categories :
| 1.  | Logical Operators. |            |     |     |     |     |     |
| --- | ------------------ | ---------- | --- | --- | --- | --- | --- |
| 2.  | Relational         | Operators. |     |     |     |     |     |
3. Shift Operators.
| 4.  | Adding Operators. |     |     |     |     |     |     |
| --- | ----------------- | --- | --- | --- | --- | --- | --- |
5. Sign Operators.
| 6.               | Multiplying   | Operators. |     |           |       |     |     |
| ---------------- | ------------- | ---------- | --- | --------- | ----- | --- | --- |
| 7.               | Miscellaneous | Operators. |     |           |       |     |     |
| (cid:13)c CEERI, | Pilani        |            |     | IC Design | Group |     | 35  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
VHDL
|                  |           |           |        | Operators | in    |     |
| ---------------- | --------- | --------- | ------ | --------- | ----- | --- |
| Logical          | Operators | :         |        |           |       |     |
| and, or,         | nand,     | nor, xor, | xnor,  | not       |       |     |
| Example          | :         |           |        |           |       |     |
| variable         | SUM,      | A, B      | : BIT; |           |       |     |
| SUM :=           | A xor     | B;        |        |           |       |     |
| (cid:13)c CEERI, | Pilani    |           |        | IC Design | Group | 36  |

| VHDL                   | Tutorial :       | Constructs |                          |           |       |     |
| ---------------------- | ---------------- | ---------- | ------------------------ | --------- | ----- | --- |
| Relational             |                  | Operators  | :                        |           |       |     |
| =, /=,                 | <, <=,           | >, >=      |                          |           |       |     |
| Example                | :                |            |                          |           |       |     |
| type                   | FOUR_LOGIC_LEVEL |            | is (’U’,’0’,’1’,’Z’);    |           |       |     |
| FOUR_LOGIC_LEVEL’(’U’) |                  |            | < FOUR_LOGIC_LEVEL’(’Z’) |           |       |     |
| if (A                  | < 10)            | then       | Z <= ’1’;                |           |       |     |
| if (TEMP               | >=               | CHECK)     | then KOUT                | := ’0’;   |       |     |
| (cid:13)c CEERI,       | Pilani           |            |                          | IC Design | Group | 37  |

| VHDL Tutorial | : Constructs   |     |     |     |     |     |
| ------------- | -------------- | --- | --- | --- | --- | --- |
| Shift         | Operators      | :   |     |     |     |     |
| Logical       | (cid:150) sll, | srl |     |     |     |     |
sla, sra
| Arithmetic       | (cid:150)      |             |           |           |       |     |
| ---------------- | -------------- | ----------- | --------- | --------- | ----- | --- |
| Rotate           | (cid:150) rol, | ror.        |           |           |       |     |
| Example          | :              |             |           |           |       |     |
| "1001010"        |                | sll 2 gives | "0101000" |           |       |     |
| "1001010"        |                | rol 2 gives | "0101010" |           |       |     |
| (cid:13)c CEERI, | Pilani         |             |           | IC Design | Group | 38  |

| VHDL             | Tutorial :        | Constructs |        |           |            |             |     |
| ---------------- | ----------------- | ---------- | ------ | --------- | ---------- | ----------- | --- |
| Adding           | Operators         |            | :      |           |            |             |     |
| +, -,            | & (concatenation) |            |        |           |            |             |     |
| Example          | :                 |            |        |           |            |             |     |
| variable         |                   | SUM1,      | SUM2,  | A, B      | : integer; |             |     |
| SUM1             | := A              | + B;       |        |           |            |             |     |
| SUM2             | := A              | - B;       |        |           |            |             |     |
| constant         |                   | S1 :       | string | := "abc"; |            |             |     |
| constant         |                   | S2 :       | string | := "def"; |            |             |     |
| constant         |                   | S3 :       | string | := S1     | & S2;      | -- "abcdef" |     |
| (cid:13)c CEERI, | Pilani            |            |        |           | IC Design  | Group       | 39  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
| Sign          | Operators    | :   |     |     |     |     |
+ and - are the two sign operators. They are prede(cid:2)ned for any numeric type,
| and have    | their      | usual     | mathematical    | meaning. |     |     |
| ----------- | ---------- | --------- | --------------- | -------- | --- | --- |
| Multiplying |            | Operators | :               |          |     |     |
| *, /, mod   | (modulus), |           | rem (remainder) |          |     |     |
mod and rem operators operate on operands of integer types and the result is
| also of          | the same | type.   |      |           |       |     |
| ---------------- | -------- | ------- | ---- | --------- | ----- | --- |
| Example          | :        |         |      |           |       |     |
| A rem            | B = A    | - (A/B) | * B. |           |       |     |
| (cid:13)c CEERI, | Pilani   |         |      | IC Design | Group | 40  |

| VHDL | Tutorial : | Constructs |     |     |     |     |     |     |     |
| ---- | ---------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
| (-7) | rem 4      | has value  | -3. |     |     |     |     |     |     |
The result of rem operator has the sign of its (cid:2)rst operand.
| A mod | B =  | A -       | B * N | -- for | some | integer |     | N.  |     |
| ----- | ---- | --------- | ----- | ------ | ---- | ------- | --- | --- | --- |
| 7 mod | (-4) | has value | -1.   |        |      |         |     |     |     |
The result of mod operator has the sign of the second operand.
| What | is the | result | of the | following | operation |     | ?   |     |     |
| ---- | ------ | ------ | ------ | --------- | --------- | --- | --- | --- | --- |
| (-7) | mod 4  | = ?    |        |           |           |     |     |     |     |
rem
| 7                | (-4)   | = ? |     |     |           |       |     |     |     |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- | --- | --- |
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group |     |     | 41  |

| VHDL Tutorial   | : Constructs |                     |     |     |     |
| --------------- | ------------ | ------------------- | --- | --- | --- |
| Miscellaneous   |              | Operators           | :   |     |     |
| abs (absolute), |              | ** (exponentiation) |     |     |     |
abs is de(cid:2)ned for any numeric type. Exponentiation operator is de(cid:2)ned for the
left operand to be of integer or (cid:3)oating-point type and the exponent to be of
| integer          | type only. |     |           |       |     |
| ---------------- | ---------- | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani     |     | IC Design | Group | 42  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Objects | in  | : Signals |     |
| --- | --- | --- | ------- | --- | --------- | --- |
For objects of this class, the language maintains a data structure (called driver
signal
of the signal) that records the time and value of each assignment to the
(called transaction). Certain predicted transactions are dropped from the driver
to be consistent with the delay model used. Thus, the driver of a signal main-
tains the current value as well as predicted or assigned future waveform ele-
| ments | for the | signal. |     |     |     |     |
| ----- | ------- | ------- | --- | --- | --- | --- |
signal
Each concurrent statement that assigns to a produces a driver for the
signal.
signal
If a is assigned to by more than one concurrent statement, then it is a
multi-writer signal and it must be declared as a resolved signal by specifying
a resolution function in the declaration of the signal. The resolution function
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 43  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
takes all the values that individual drivers wish to assign to the signal and
resolves them to produce a single value that is actually assigned to the signal.
Objects of signal class are created through signal declaration statement.
| Example | :            |                |                |        |       |        |     |
| ------- | ------------ | -------------- | -------------- | ------ | ----- | ------ | --- |
| signal  | X : BIT;     |                |                |        |       |        |     |
| signal  | Y : BIT      | :=             | ’1’;           |        |       |        |     |
| -- note | the          | signal         | initialization |        | !     |        |     |
| signal  | X_BUS        | : BIT_vector(7 |                | downto | 0) := | X"FF"; |     |
| signal  | Z : WIRED_OR |                | BIT;           |        |       |        |     |
Z is a resolved signal of type BIT, with WIRED OR as the resolution function.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     | 44  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
One can also de(cid:2)ne a resolved subtype of a type and then use the resolved
| subtype          | to declare        | a resolved | signal.     |           |       |     |
| ---------------- | ----------------- | ---------- | ----------- | --------- | ----- | --- |
| Example          | :                 |            |             |           |       |     |
| subtype          | RESOLVED_BIT      |            | is WIRED_OR |           | BIT;  |     |
| signal           | Z : RESOLVED_BIT; |            |             |           |       |     |
| (cid:13)c CEERI, | Pilani            |            |             | IC Design | Group | 45  |

| VHDL     | Tutorial   | : Constructs    |          |       |     |             |               |     |     |
| -------- | ---------- | --------------- | -------- | ----- | --- | ----------- | ------------- | --- | --- |
|          |            |                 |          | WIRED | OR  |             |               |     |     |
| The      | resolution |                 | function |       |     | may         | be as follows | :   |     |
| function |            | WIRED_OR(INPUTS |          |       | :   | BIT_vector) |               |     |     |
| return   |            | BIT             | is       |       |     |             |               |     |     |
begin
| --               | implicit  |           | declaration  |       | of   | J as      | integer | type |     |
| ---------------- | --------- | --------- | ------------ | ----- | ---- | --------- | ------- | ---- | --- |
| for              | J         | in        | INPUTS’range |       | loop |           |         |      |     |
|                  | if        | INPUTS(J) |              | = ’1’ | then |           |         |      |     |
|                  | return    |           | ’1’;         |       |      |           |         |      |     |
|                  | end       | if;       |              |       |      |           |         |      |     |
| end              | loop;     |           |              |       |      |           |         |      |     |
| return           |           | ’0’;      |              |       |      |           |         |      |     |
| end              | WIRED_OR; |           |              |       |      |           |         |      |     |
| (cid:13)c CEERI, | Pilani    |           |              |       |      | IC Design | Group   |      | 46  |

| VHDL Tutorial | : Constructs |        |              |     |      |     |     |     |
| ------------- | ------------ | ------ | ------------ | --- | ---- | --- | --- | --- |
| Objects       | of class     | signal | are declared |     | in : |     |     |     |
(cid:15)
architecture-item-declaration zone : signals declared here are accessible
| throughout |     | the architecture |     | body, | but not | outside | it. |     |
| ---------- | --- | ---------------- | --- | ----- | ------- | ------- | --- | --- |
(cid:15) entity-item-declaration zone : signals declared here are accessible through-
| out | all the | architecture | bodies | associated |     | with the | entity. |     |
| --- | ------- | ------------ | ------ | ---------- | --- | -------- | ------- | --- |
(cid:15)
block-item-declaration zone of a concurrent block statement : signals de-
clared here are accessible throughout the block (including any nested sub-
blocks).
(cid:15)
| in               | package | declarations. |     |           |       |     |     |     |
| ---------------- | ------- | ------------- | --- | --------- | ----- | --- | --- | --- |
| (cid:13)c CEERI, | Pilani  |               |     | IC Design | Group |     |     | 47  |

| VHDL Tutorial | : Constructs |     |           |     |     |     |     |     |     |     |     |
| ------------- | ------------ | --- | --------- | --- | --- | --- | --- | --- | --- | --- | --- |
| Creating      | Signal       |     | Waveforms |     |     |     |     |     |     |     |     |
Phase 1
|        |         |      |       |          | T   | T+8     | T+13 |           | T+50 ns |           |     |
| ------ | ------- | ---- | ----- | -------- | --- | ------- | ---- | --------- | ------- | --------- | --- |
| Phase1 | <=      | ’0’, | ’1’   | after    | 8   | ns,     | ’0’  | after     | 13      | ns,       |     |
|        |         | ’1’  | after | 50       | ns; |         |      |           |         |           |     |
| Signal | Drivers |      |       |          |     |         |      |           |         |           |     |
|        |         |      |       | curr@now |     | 3@T+5ns |      | 21@T+10ns |         | 14@T+17ns |     |
RESET
| RESET            | <= 3   | after | 5   | ns,    | 21  | after |        | 10 ns, |     |     |     |
| ---------------- | ------ | ----- | --- | ------ | --- | ----- | ------ | ------ | --- | --- | --- |
|                  | 14     | after |     | 17 ns; |     |       |        |        |     |     |     |
| (cid:13)c CEERI, | Pilani |       |     |        |     | IC    | Design | Group  |     |     | 48  |

| VHDL Tutorial | :            | Constructs |       |          |        |           |           |     |
| ------------- | ------------ | ---------- | ----- | -------- | ------ | --------- | --------- | --- |
| Effect        | of Transport |            | Delay | on       | Signal | Drivers   |           |     |
|               |              | RX_DATA    |       | curr@now |        | 11@T+10ns | 20@T+22ns |     |
|               |              |            |       | curr@now |        | 11@T+10ns | 35@T+18ns |     |
RX_DATA
| signal | RX_DATA |     | : NATURAL; |     |     |     |     |     |
| ------ | ------- | --- | ---------- | --- | --- | --- | --- | --- |
...
process
begin
...
| RX_DATA          |        | <= transport |     | 11  | after     | 10 ns; |     |     |
| ---------------- | ------ | ------------ | --- | --- | --------- | ------ | --- | --- |
| (cid:13)c CEERI, | Pilani |              |     |     | IC Design | Group  |     | 49  |

| VHDL | Tutorial | : Constructs |     |     |     |     |     |     |
| ---- | -------- | ------------ | --- | --- | --- | --- | --- | --- |
...
|     | RX_DATA | <=  | transport |     | 20  | after | 22 ns; |     |
| --- | ------- | --- | --------- | --- | --- | ----- | ------ | --- |
...
|     | RX_DATA | <=  | transport |     | 35  | after | 18 ns; |     |
| --- | ------- | --- | --------- | --- | --- | ----- | ------ | --- |
...
| end | process; |     |     |     |     |     |     |     |
| --- | -------- | --- | --- | --- | --- | --- | --- | --- |
The following summarizes the rules for adding a new transaction to a driver
| when | transport |     | delay | is used | :   |     |     |     |
| ---- | --------- | --- | ----- | ------- | --- | --- | --- | --- |
1. If the delay time of the new transaction is greater than those of all the
transactions already present on the driver, then the new transaction is
|                  | added  | at  | the end | of the | driver. |           |       |     |
| ---------------- | ------ | --- | ------- | ------ | ------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |     |         |        |         | IC Design | Group | 50  |

| VHDL Tutorial | : Constructs |     |     |     |
| ------------- | ------------ | --- | --- | --- |
2. If the delay time of the new transaction is earlier than or equal to one or
more transactions on the driver, then these transactions are deleted from
the driver and the new transaction is added at the end of the driver.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 51  |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | :           | Constructs |       |           |         |     |     |
| ------------- | ----------- | ---------- | ----- | --------- | ------- | --- | --- |
| Effect        | of Inertial |            | Delay | on Signal | Drivers |     |     |
curr@now 22@20ns
TX_DATA
curr@now
TX_DATA 33@15ns
process
begin
| TX_DATA          |          | <=       | 11 after | 10 ns;        |           |       |     |
| ---------------- | -------- | -------- | -------- | ------------- | --------- | ----- | --- |
| TX_DATA          |          | <=       | 22 after | 20 ns;        |           |       |     |
| TX_DATA          |          | <=       | 33 after | 15 ns;        |           |       |     |
| wait;            | --       | suspends |          | indefinitely. |           |       |     |
| end              | process; |          |          |               |           |       |     |
| (cid:13)c CEERI, | Pilani   |          |          |               | IC Design | Group | 52  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
The summary of rules for adding a new transaction when inertial delay is used :
1. All transactions on a driver that are scheduled to occur at or after the delay
of the new transaction are deleted (as in the transport case).
2. If the value of the new transaction is the same as the value of the transac-
tions on the driver, the new transaction is added to the driver.
3. If the value of the new transaction is different from the values of one or
more transactions on the driver, these transactions are deleted from the
| driver | and | the new | transaction | is  | added. |     |
| ------ | --- | ------- | ----------- | --- | ------ | --- |
4. For a single signal assignment statement, if the (cid:2)rst waveform element
is added to the driver, all subsequent waveforms elements of that signal
| assignment       |        | are also | added | to the    | driver. |     |
| ---------------- | ------ | -------- | ----- | --------- | ------- | --- |
| (cid:13)c CEERI, | Pilani |          |       | IC Design | Group   | 53  |

| VHDL Tutorial | : Constructs |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- |
VHDL
|     |     | Objects | in  | : Variables |     |
| --- | --- | ------- | --- | ----------- | --- |
Objects of this class only have a value. No timing information of their value
changes is recorded or maintained. They are merely storage locations for
values/results of expressions/intermediate results of computation/passing of
VHDL process
parameters in sequential parts of the code (inside statement)
exactly in the same way as variables are used in any procedural language like
C.
(cid:15) Variables can be declared in the process-item-declaration zone : variables
so declared are initialized only once (cid:151) at the start of the simulation run.
They can be assigned to any where throughout the sequential part of
the process statement in which they are de(cid:2)ned (including in the nested
function calls). They retain their values when processes get suspended
| i.e.             | in-between | process | activations. |       |     |
| ---------------- | ---------- | ------- | ------------ | ----- | --- |
| (cid:13)c CEERI, | Pilani     |         | IC Design    | Group | 54  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
(cid:15) Variables can also be declared in the declaration zone of procedure bodies
and function bodies. Variables so declared are initialized every time a call
is made to the procedure or function i.e. they do not retain their values
| across           | calls.      |                 |           |           |        |     |     |
| ---------------- | ----------- | --------------- | --------- | --------- | ------ | --- | --- |
| Example          | :           |                 |           |           |        |     |     |
| variable         | STATUS      | : BIT_vector(15 |           |           | downto | 0); |     |
| variable         | SUM :       | integer         | range     | 0 to      | 10 :=  | 5;  |     |
| variable         | ACKNOWLEDGE |                 | : Boolean | :=        | TRUE;  |     |     |
| (cid:13)c CEERI, | Pilani      |                 |           | IC Design | Group  |     | 55  |

| VHDL Tutorial | : Constructs |         |         |             |     |
| ------------- | ------------ | ------- | ------- | ----------- | --- |
|               |              | Objects | in VHDL | : Constants |     |
constant
Objects of class can be assigned values only once (cid:151) at the time of
| their declaration. |     |     |     |     |     |
| ------------------ | --- | --- | --- | --- | --- |
There is a small exception though. It is possible for constants declared in
a package not to be assigned value at the time of their declaration. Their
values may be assigned in the packaged body by repeating the full constant
declaration along with the value assignment there. Such constants are called
| deferred         | constants. |           |           |       |     |
| ---------------- | ---------- | --------- | --------- | ----- | --- |
| Example          | :          |           |           |       |     |
| constant         | RISE_TIME  | : TIME    | := 10     | ns;   |     |
| constant         | BUS_WIDTH  | : integer | :=        | 8;    |     |
| (cid:13)c CEERI, | Pilani     |           | IC Design | Group | 56  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Sequential | Statements |     | in  |     |
| --- | --- | --- | ---------- | ---------- | --- | --- | --- |
Following is the list of sequential statements used in a process :
| (cid:15) variable |            | assignment | statement. |           |       |     |     |
| ----------------- | ---------- | ---------- | ---------- | --------- | ----- | --- | --- |
| (cid:15) signal   | assignment |            | statement. |           |       |     |     |
| (cid:15) wait     | statement. |            |            |           |       |     |     |
| (cid:15) if       | statement. |            |            |           |       |     |     |
| (cid:13)c CEERI,  | Pilani     |            |            | IC Design | Group |     | 57  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
(cid:11) (cid:8)
VHDL
|     |     | Sequential | Statements |     | in  |     |
| --- | --- | ---------- | ---------- | --- | --- | --- |
(cid:10) (cid:9)
| (cid:15) case    | statement. |     |           |       |     |     |
| ---------------- | ---------- | --- | --------- | ----- | --- | --- |
| (cid:15) loop    | statement. |     |           |       |     |     |
| (cid:15) next    | statement. |     |           |       |     |     |
| (cid:15) exit    | statement. |     |           |       |     |     |
| (cid:15) null    | statement. |     |           |       |     |     |
| (cid:13)c CEERI, | Pilani     |     | IC Design | Group |     | 58  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
(cid:11) (cid:8)
VHDL
|     |     | Sequential | Statements |     | in  |     |
| --- | --- | ---------- | ---------- | --- | --- | --- |
(cid:10) (cid:9)
(cid:15) report statement.
(cid:15) assertion
statement.
(cid:15) procedure call statement.
(cid:15)
return statement.
| (cid:13)c CEERI, | Pilani |     | IC Design | Group |     | 59  |
| ---------------- | ------ | --- | --------- | ----- | --- | --- |

| VHDL Tutorial       | : Constructs |       |                |            |           |         |     |
| ------------------- | ------------ | ----- | -------------- | ---------- | --------- | ------- | --- |
|                     |              |       | Sequential     | Statements |           | in VHDL |     |
|                     |              |       | Variable       | Assignment | Statement |         |     |
| Syntax              | :            |       |                |            |           |         |     |
| variable_identifier |              |       | := expression; |            |           |         |     |
| Example             | :            |       |                |            |           |         |     |
| P1 :                | process      |       |                |            |           |         |     |
| -- initialization   |              |       | statement      |            |           |         |     |
| variable            |              | count | : integer      | := 0;      |           |         |     |
| (cid:13)c CEERI,    | Pilani       |       |                | IC Design  | Group     |         | 60  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
begin
| . .              | .             |         |         |           |       |      |     |
| ---------------- | ------------- | ------- | ------- | --------- | ----- | ---- | --- |
| count            | := count      | + 1;    |         |           |       |      |     |
| . .              | .             |         |         |           |       |      |     |
| wait;            | -- indefinite |         | wait    |           |       |      |     |
| end process;     |               | -- this | process | executes  | only  | once |     |
| (cid:13)c CEERI, | Pilani        |         |         | IC Design | Group |      | 61  |

| VHDL              | Tutorial : Constructs |     |                |            |       |           |     |
| ----------------- | --------------------- | --- | -------------- | ---------- | ----- | --------- | --- |
|                   |                       |     | Sequential     | Statements |       | in VHDL   |     |
|                   |                       |     | Signal         | Assignment |       | Statement |     |
| Syntax            | :                     |     |                |            |       |           |     |
| signal_identifier |                       |     | <= [transport] |            | value |           |     |
[after time_expression
|     | {, value | after | time_expression}] |     |     | ;   |     |
| --- | -------- | ----- | ----------------- | --- | --- | --- | --- |
Example :
| signal           | A : BIT      | :=  | ’0’; |           |       |     |     |
| ---------------- | ------------ | --- | ---- | --------- | ----- | --- | --- |
| signal           | B : BIT      | :=  | ’1’; |           |       |     |     |
| P1               | : process(A) |     |      |           |       |     |     |
| (cid:13)c CEERI, | Pilani       |     |      | IC Design | Group |     | 62  |

| VHDL Tutorial | : Constructs |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- |
begin
| . .              | .       |        |           |       |     |
| ---------------- | ------- | ------ | --------- | ----- | --- |
| B <=             | A after | 10 ms; |           |       |     |
| . .              | .       |        |           |       |     |
| end process;     |         |        |           |       |     |
| (cid:13)c CEERI, | Pilani  |        | IC Design | Group | 63  |

| VHDL | Tutorial : Constructs |     |            |            |     |         |     |     |     |
| ---- | --------------------- | --- | ---------- | ---------- | --- | ------- | --- | --- | --- |
|      |                       |     | Sequential | Statements |     | in VHDL |     |     |     |
Wait Statement
| Syntax | :                    |                     |             |           |            |      |         |      |        |
| ------ | -------------------- | ------------------- | ----------- | --------- | ---------- | ---- | ------- | ---- | ------ |
| wait   | on sensitivity_list; |                     |             |           |            |      |         |      |        |
| wait   | until                | boolean_expression; |             |           |            |      |         |      |        |
| wait   | for time_expression; |                     |             |           |            |      |         |      |        |
| These  | may                  | be combined         | in a single | wait      | statement. |      |         |      |        |
| wait   | on sensitivity_list  |                     |             |           |            |      |         |      |        |
| until  | boolean_expression   |                     |             |           |            |      |         |      |        |
| for    | time_expression;     |                     |             |           |            |      |         |      |        |
|        |                      | process             |             |           |            |      |         | wait |        |
| The    | execution            | of                  | is always   | suspended |            | when | you hit | the  | state- |
ment.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     |     |     | 64  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- | --- | --- |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
process
process(A,B)
begin
begin
|              |     |     | (cid:17) |     | .    | . .      |      |
| ------------ | --- | --- | -------- | --- | ---- | -------- | ---- |
| . .          | .   |     |          |     |      |          |      |
|              |     |     |          |     | wait | on       | A,B; |
| end process; |     |     |          |     |      |          |      |
|              |     |     |          |     | end  | process; |      |
process
process
begin
begin
|      |      |     |     |     | A <= | ’1’;  |     |
| ---- | ---- | --- | --- | --- | ---- | ----- | --- |
| A <= | ’1’; |     |     |     |      |       |     |
|      |      |     |     |     | wait | for 0 | ns; |
vs.
| B <=         | A;      |     |     |     |      |         |     |
| ------------ | ------- | --- | --- | --- | ---- | ------- | --- |
|              |         |     |     |     | B <= | A;      |     |
| wait         | for 100 | ns; |     |     |      |         |     |
|              |         |     |     |     | wait | for 100 | ns; |
| end process; |         |     |     |     |      |         |     |
end process;
| (cid:13)c CEERI, | Pilani |     | IC Design | Group |     |     | 65  |
| ---------------- | ------ | --- | --------- | ----- | --- | --- | --- |

| VHDL    | Tutorial | : Constructs |     |         |     |           |     |      |        |      |     |
| ------- | -------- | ------------ | --- | ------- | --- | --------- | --- | ---- | ------ | ---- | --- |
| Example |          | :            |     |         |     |           |     |      |        |      |     |
| wait    | on       | A,           | B,  | C;      |     |           |     |      |        |      |     |
| wait    | until    |              | A   | = B;    |     |           |     |      |        |      |     |
| wait    | for      | 10           | ns; |         |     |           |     |      |        |      |     |
| wait    | on       | CLOCK        |     | for     | 20  | ns;       | --  | max. | 20 ns  | wait |     |
| wait    | on       | CARRY        |     | until   |     | (SUM      | >   | 100) | for 50 | ms;  |     |
| Example |          | : Use        |     | of wait |     | statement |     |      |        |      |     |
process
| variable |     |     | Temp1, |     | Temp2 |     | :   | BIT; |     |     |     |
| -------- | --- | --- | ------ | --- | ----- | --- | --- | ---- | --- | --- | --- |
begin
| Temp1            |        | :=  | A   | and | B;  |     |     |           |       |     |     |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |     |     |     |     |     |     | IC Design | Group |     | 66  |

| VHDL             | Tutorial : Constructs |            |     |           |       |     |
| ---------------- | --------------------- | ---------- | --- | --------- | ----- | --- |
| wait             | for 5                 | ns;        |     |           |       |     |
| Temp2            | := C                  | and D;     |     |           |       |     |
| wait             | for 3                 | ns;        |     |           |       |     |
| Z                | <= Temp1              | or Temp2;  |     |           |       |     |
| wait             | on A,                 | B, C,      | D;  |           |       |     |
| -- a             | process               | can have   |     |           |       |     |
| -- many          | wait                  | statements |     |           |       |     |
| end              | process;              |            |     |           |       |     |
| (cid:13)c CEERI, | Pilani                |            |     | IC Design | Group | 67  |

| VHDL Tutorial | : Constructs |            |            |     |         |     |
| ------------- | ------------ | ---------- | ---------- | --- | ------- | --- |
|               |              | Sequential | Statements |     | in VHDL |     |
If Statement
| Syntax                | :   |      |     |     |     |     |
| --------------------- | --- | ---- | --- | --- | --- | --- |
| if boolean-expression |     | then |     |     |     |     |
sequential-statements
| {elsif | boolean-expression |     | then |     |     |     |
| ------ | ------------------ | --- | ---- | --- | --- | --- |
sequential-statements}
| [else            | sequential-statements] |     |           |       |     |     |
| ---------------- | ---------------------- | --- | --------- | ----- | --- | --- |
| end if;          |                        |     |           |       |     |     |
| (cid:13)c CEERI, | Pilani                 |     | IC Design | Group |     | 68  |

| VHDL Tutorial | : Constructs |     |     |     |
| ------------- | ------------ | --- | --- | --- |
The sequential statement(s) associated with the (cid:2)rst boolean-expression
if
which evaluates to TRUE of the statement is executed even when many
other boolean-expressions may evaluate to TRUE. Therefore, the order of
| the boolean-expressions | is important. |           |       |     |
| ----------------------- | ------------- | --------- | ----- | --- |
| (cid:13)c CEERI,        | Pilani        | IC Design | Group | 69  |

| VHDL        | Tutorial | :   | Constructs |           |     |     |     |     |     |     |     |     |
| ----------- | -------- | --- | ---------- | --------- | --- | --- | --- | --- | --- | --- | --- | --- |
| Example     |          | :   |            |           |     |     |     |     |     |     |     |     |
| And_Process |          |     |            | : process |     |     |     |     |     |     |     |     |
begin
| if               | (In1     |        | =    | ’0’ | or    | In2   | =      | ’0’)   |        | then   |       |     |
| ---------------- | -------- | ------ | ---- | --- | ----- | ----- | ------ | ------ | ------ | ------ | ----- | --- |
|                  | Zout     |        | <=   | ’0’ | after |       | delay; |        |        |        |       |     |
| elsif            |          | (In1   |      | =   | ’X’   | or    | In2    |        | = ’X’) |        | then  |     |
|                  | Zout     |        | <=   | ’X’ | after |       | delay; |        |        |        |       |     |
| else             |          | Zout   |      | <=  | ’1’   | after |        | delay; |        |        |       |     |
| end              |          | if;    |      |     |       |       |        |        |        |        |       |     |
| wait             |          | on     | In1, |     | In2;  |       |        |        |        |        |       |     |
| end              | process; |        |      |     |       |       |        |        |        |        |       |     |
| (cid:13)c CEERI, |          | Pilani |      |     |       |       |        |        | IC     | Design | Group | 70  |

| VHDL   | Tutorial : Constructs |                          |                |     |         |     |
| ------ | --------------------- | ------------------------ | -------------- | --- | ------- | --- |
|        |                       | Sequential               | Statements     |     | in VHDL |     |
|        |                       |                          | Case Statement |     |         |     |
| Syntax | :                     |                          |                |     |         |     |
| case   | discrete-expression   |                          | is             |     |         |     |
|        |                       | -- branch                | #1             |     |         |     |
| when   | choices               | => sequential-statements |                |     |         |     |
|        |                       | -- branch                | #2             |     |         |     |
| when   | choices               | => sequential-statements |                |     |         |     |
|        |                       | -- more                  | branches       |     |         |     |
...
|                  |        | -- last | branch    |       |     |     |
| ---------------- | ------ | ------- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |         | IC Design | Group |     | 71  |

| VHDL Tutorial | : Constructs |     |                           |     |     |     |
| ------------- | ------------ | --- | ------------------------- | --- | --- | --- |
| [when         | others       |     | => sequential-statements] |     |     |     |
| end           | case;        |     |                           |     |     |     |
discrete-expression’s all possible discrete values should be considered and
| taken            | care of | in the | choices | section.  |       |     |
| ---------------- | ------- | ------ | ------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani  |        |         | IC Design | Group | 72  |

| VHDL                | Tutorial | : Constructs |     |           |     |     |     |     |
| ------------------- | -------- | ------------ | --- | --------- | --- | --- | --- | --- |
| Example             |          | :            |     |           |     |     |     |     |
| Multiplexer_Process |          |              |     | : process |     |     |     |     |
begin
| case             |          | SELECTOR     | is      |      |      |           |        |     |
| ---------------- | -------- | ------------ | ------- | ---- | ---- | --------- | ------ | --- |
|                  | when     | "00"         | => Zout | <=   | In0  | after     | delay; |     |
|                  | when     | "01"         | => Zout | <=   | In1  | after     | delay; |     |
|                  | when     | "10"         | => Zout | <=   | In2  | after     | delay; |     |
|                  | when     | "11"         | => Zout | <=   | In3  | after     | delay; |     |
| end              |          | case;        |         |      |      |           |        |     |
| wait             |          | on SELECTOR, |         | In0, | In1, | In2,      | In3;   |     |
| end              | process; |              |         |      |      |           |        |     |
| (cid:13)c CEERI, |          | Pilani       |         |      |      | IC Design | Group  | 73  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Sequential | Statements |     | in  |     |
| --- | --- | --- | ---------- | ---------- | --- | --- | --- |
Loop Statement
| Syntax      | :   |         |     |     |     |     |     |
| ----------- | --- | ------- | --- | --- | --- | --- | --- |
| [loop-label |     | :] loop |     |     |     |     |     |
sequential-statements
| end loop    | [loop-label]; |          |           |      |     |     |     |
| ----------- | ------------- | -------- | --------- | ---- | --- | --- | --- |
| [loop-label |               | :] while | condition | loop |     |     |     |
sequential-statements
| end loop         | [loop-label]; |     |     |           |       |     |     |
| ---------------- | ------------- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani        |     |     | IC Design | Group |     | 74  |

| VHDL        | Tutorial : Constructs |        |               |     |          |      |     |
| ----------- | --------------------- | ------ | ------------- | --- | -------- | ---- | --- |
| [loop_label |                       | :] for | loop-variable |     | in range | loop |     |
sequential-statements
| end      | loop    | [loop-label]; |       |     |     |     |     |
| -------- | ------- | ------------- | ----- | --- | --- | --- | --- |
| Loops    | can     | be nested.    |       |     |     |     |     |
| Example  | :       |               |       |     |     |     |     |
| P1 :     | process |               |       |     |     |     |     |
| variable |         | A : integer   | := 0; |     |     |     |     |
| variable |         | B : integer   | := 0; |     |     |     |     |
begin
| L1               | : loop    |           |      |           |       |     |     |
| ---------------- | --------- | --------- | ---- | --------- | ----- | --- | --- |
|                  | A := A    | + 1;      |      |           |       |     |     |
|                  | B := 20;  |           |      |           |       |     |     |
|                  | L2 : loop |           |      |           |       |     |     |
|                  | if B      | < (A * A) | then |           |       |     |     |
| (cid:13)c CEERI, | Pilani    |           |      | IC Design | Group |     | 75  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
exit L2;
end if;
|      | B := B - A; |         |     |     |     |     |
| ---- | ----------- | ------- | --- | --- | --- | --- |
| end  | loop L2;    |         |     |     |     |     |
| exit | L1 when     | A > 10; |     |     |     |     |
| end  | loop L1;    |         |     |     |     |     |
wait;
end process;
| P1 : process |             |     |     |     |     |     |
| ------------ | ----------- | --- | --- | --- | --- | --- |
| variable     | B : integer | :=  | 1;  |     |     |     |
begin
| L1 :             | for A in | 1 to 10 | loop |           |       |     |
| ---------------- | -------- | ------- | ---- | --------- | ----- | --- |
| B                | := 20;   |         |      |           |       |     |
| (cid:13)c CEERI, | Pilani   |         |      | IC Design | Group | 76  |

| VHDL Tutorial | : Constructs |         |           |     |     |     |
| ------------- | ------------ | ------- | --------- | --- | --- | --- |
| L2            | : while      | B >= (A | * A) loop |     |     |     |
|               | B := B       | - A;    |           |     |     |     |
| end           | loop         | L2;     |           |     |     |     |
| end           | loop L1;     |         |           |     |     |     |
wait;
end process;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 77  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial : Constructs |            |                |     |         |     |
| ---- | --------------------- | ---------- | -------------- | --- | ------- | --- |
|      |                       | Sequential | Statements     |     | in VHDL |     |
|      |                       |            | Next Statement |     |         |     |
This is used only inside a loop to go to the next iteration of the loop.
| Syntax           | :            |       |             |       |     |     |
| ---------------- | ------------ | ----- | ----------- | ----- | --- | --- |
| next             | [loop-label] | [when | condition]; |       |     |     |
| (cid:13)c CEERI, | Pilani       |       | IC Design   | Group |     | 78  |

| VHDL     | Tutorial | : Constructs |     |     |     |     |     |
| -------- | -------- | ------------ | --- | --- | --- | --- | --- |
| Example  | :        |              |     |     |     |     |     |
| P1 :     | process  |              |     |     |     |     |     |
| variable |          | B : integer  | :=  | 1;  |     |     |     |
begin
| L1  | : for    | A in    | 1 to 10 | loop     |     |     |     |
| --- | -------- | ------- | ------- | -------- | --- | --- | --- |
|     | B :=     | 20;     |         |          |     |     |     |
|     | L2 :     | loop    |         |          |     |     |     |
|     | B :=     | B - A;  |         |          |     |     |     |
|     | next     | L1 when | B <     | (A * A); |     |     |     |
|     | end loop | L2;     |         |          |     |     |     |
| end | loop     | L1;     |         |          |     |     |     |
wait;
end process;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 79  |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL             | Tutorial : Constructs |        |            |             |            |       |             |     |
| ---------------- | --------------------- | ------ | ---------- | ----------- | ---------- | ----- | ----------- | --- |
|                  |                       |        | Sequential |             | Statements |       | in VHDL     |     |
|                  |                       |        |            | Exit        | Statement  |       |             |     |
| This             | is used only          | inside | a loop     | to          | exit the   | loop  | completely. |     |
| Syntax           | :                     |        |            |             |            |       |             |     |
| exit             | [loop-label]          |        | [when      | condition]; |            |       |             |     |
| (cid:13)c CEERI, | Pilani                |        |            |             | IC Design  | Group |             | 80  |

| VHDL Tutorial | : Constructs |                       |             |     |       |     |     |
| ------------- | ------------ | --------------------- | ----------- | --- | ----- | --- | --- |
| Example       | :            |                       |             |     |       |     |     |
| SUM :=        | 1;           |                       |             |     |       |     |     |
| J := 0;       |              |                       |             |     |       |     |     |
| L3 : loop     |              |                       |             |     |       |     |     |
| J :=          | J + 21;      |                       |             |     |       |     |     |
| SUM           | := SUM       | * 10;                 |             |     |       |     |     |
| if (SUM       | > 1000)      |                       | then        |     |       |     |     |
| exit          | L3;          |                       |             |     |       |     |     |
| -- "exit;"    | is           | also                  | sufficient, | as  | it    |     |     |
| -- exits      | the          | immediately-enclosing |             |     | loop. |     |     |
| end           | if;          |                       |             |     |       |     |     |
| end loop      | L3;          |                       |             |     |       |     |     |
or
| SUM :=           | 1;      |       |          |     |           |       |     |
| ---------------- | ------- | ----- | -------- | --- | --------- | ----- | --- |
| J := 0;          |         |       |          |     |           |       |     |
| L3 : loop        |         |       |          |     |           |       |     |
| J :=             | J + 21; |       |          |     |           |       |     |
| SUM              | := SUM  | * 10; |          |     |           |       |     |
| exit             | L3 when | (SUM  | > 1000); |     |           |       |     |
| end loop         | L3;     |       |          |     |           |       |     |
| (cid:13)c CEERI, | Pilani  |       |          |     | IC Design | Group | 81  |

| VHDL      | Tutorial  |     | : Constructs |      |     |            |          |      |            |         |         |     |
| --------- | --------- | --- | ------------ | ---- | --- | ---------- | -------- | ---- | ---------- | ------- | ------- | --- |
|           |           |     |              |      |     | Sequential |          |      | Statements |         | in VHDL |     |
|           |           |     |              |      |     |            |          | Null | Statement  |         |         |     |
| This      | statement |     |              | does |     | not cause  |          | any  | action     | to take | place.  |     |
| Example   |           | :   |              |      |     |            |          |      |            |         |         |     |
| procedure |           |     | ModTwo(X     |      | :   | inout      | integer) |      | is         |         |         |     |
begin
|     | case | X     | is     |     |       |      |     |     |     |     |     |     |
| --- | ---- | ----- | ------ | --- | ----- | ---- | --- | --- | --- | --- | --- | --- |
|     | when |       | 0 | 1  | =>  | null; |      |     |     |     |     |     |     |
|     | when |       | others | =>  | X     | := X | mod | 2;  |     |     |     |     |
|     | end  | case; |        |     |       |      |     |     |     |     |     |     |
end ModTwo;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     |     | IC  | Design | Group |     | 82  |
| ---------------- | --- | ------ | --- | --- | --- | --- | --- | --- | ------ | ----- | --- | --- |

| VHDL Tutorial | : Constructs |     |            |            |     |         |     |
| ------------- | ------------ | --- | ---------- | ---------- | --- | ------- | --- |
|               |              |     | Sequential | Statements |     | in VHDL |     |
Report Statement
| This      | is used to        | display          | a message. |     |     |     |     |
| --------- | ----------------- | ---------------- | ---------- | --- | --- | --- | --- |
| Syntax    | :                 |                  |            |     |     |     |     |
| report    | string-expression |                  |            |     |     |     |     |
| [severity |                   | severity-level]; |            |     |     |     |     |
Severity levels are note, warning, error and failure. The default severity
note.
| level            | is     |     |     |           |       |     |     |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- |
| Example          | :      |     |     |           |       |     |     |
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     | 83  |

| VHDL Tutorial | : Constructs |         |      |           |         |     |
| ------------- | ------------ | ------- | ---- | --------- | ------- | --- |
| if (CLR       | = ’Z’)       | then    |      |           |         |     |
| report        | "Signal      | CLR has | High | Impedance | Value"; |     |
end if;
| if (CLK          | /=     | ’0’ and    | CLK /= | ’1’)      | then  |     |
| ---------------- | ------ | ---------- | ------ | --------- | ----- | --- |
| report           | "CLK   | is neither |        | ’0’ nor   | ’1’"  |     |
| severity         |        | warning;   |        |           |       |     |
| end if;          |        |            |        |           |       |     |
| (cid:13)c CEERI, | Pilani |            |        | IC Design | Group | 84  |

| VHDL Tutorial | : Constructs |     |     |     |     |     |
| ------------- | ------------ | --- | --- | --- | --- | --- |
Sequential Statements in VHDL
|     |     |     | Assertion | Statement |     |     |
| --- | --- | --- | --------- | --------- | --- | --- |
Assertion statements are useful in modeling constraints of an entity.
| Syntax           | :                |         |            |       |     |     |
| ---------------- | ---------------- | ------- | ---------- | ----- | --- | --- |
| assert           | condition        | [report | message]   |       |     |     |
| [severity        | severity-level]; |         |            |       |     |     |
| Example          | :                |         |            |       |     |     |
| assert           | Enable           | /= ’X’  |            |       |     |     |
| report           | "Unknown         | Value   | on Enable" |       |     |     |
| severity         | error;           |         |            |       |     |     |
| (cid:13)c CEERI, | Pilani           |         | IC Design  | Group |     | 85  |

| VHDL Tutorial  | : Constructs |                       |           |            |           |         |     |
| -------------- | ------------ | --------------------- | --------- | ---------- | --------- | ------- | --- |
|                |              | Sequential            |           | Statements |           | in VHDL |     |
|                |              |                       | Procedure | Call       | Statement |         |     |
| Syntax         | :            |                       |           |            |           |         |     |
| procedure-name |              | [(association-list)]; |           |            |           |         |     |
association-list may be speci(cid:2)ed using positional association or named
association.
| Example      | :         |          |     |      |     |     |     |
| ------------ | --------- | -------- | --- | ---- | --- | --- | --- |
| type OP_CODE | is        |          |     |      |     |     |     |
| (ADD,        | SUB, MUL, | DIV, LT, | LE, | EQ); |     |     |     |
. . .
| procedure        | ALU_Unit( |     |     |           |       |     |     |
| ---------------- | --------- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani    |     |     | IC Design | Group |     | 86  |

| VHDL | Tutorial |     | : Constructs |          |     |     |     |     |     |     |
| ---- | -------- | --- | ------------ | -------- | --- | --- | --- | --- | --- | --- |
|      | A, B     | :   | in integer;  |          |     |     |     |     |     |     |
|      | OP :     | in  | OP_CODE;     |          |     |     |     |     |     |     |
|      | Z :      | out | integer;     |          |     |     |     |     |     |     |
|      | ZCOMP    | :   | out          | Boolean) |     | is  |     |     |     |     |
begin
|     | case | OP    | is  |          |     |        |       |     |     |     |
| --- | ---- | ----- | --- | -------- | --- | ------ | ----- | --- | --- | --- |
|     | when |       | ADD | => Z     | :=  | A + B; |       |     |     |     |
|     | when |       | SUB | => Z     | :=  | A - B; |       |     |     |     |
|     | when |       | MUL | => Z     | :=  | A * B; |       |     |     |     |
|     | when |       | DIV | => Z     | :=  | A / B; |       |     |     |     |
|     | when |       | LT  | => ZCOMP |     | := (A  | < B); |     |     |     |
|     | when |       | LE  | => ZCOMP |     | := (A  | <=    | B); |     |     |
|     | when |       | EQ  | => ZCOMP |     | := (A  | = B); |     |     |     |
|     | end  | case; |     |          |     |        |       |     |     |     |
end ALU_Unit;
| --               | using |        | positional |              | association. |        |        |           |       |     |
| ---------------- | ----- | ------ | ---------- | ------------ | ------------ | ------ | ------ | --------- | ----- | --- |
| ALU_Unit(D1,     |       |        |            | D2,          | ADD,         | SUM,   | COMP); |           |       |     |
| --               | using |        | named      | association. |              |        |        |           |       |     |
| ALU_Unit(Z       |       |        | =>         | SUM,         | B            | => D2, | A =>   | D1,       |       |     |
|                  | OP => | ADD,   |            | ZCOMP        | =>           | COMP); |        |           |       |     |
| (cid:13)c CEERI, |       | Pilani |            |              |              |        |        | IC Design | Group | 87  |

| VHDL Tutorial | : Constructs |     |            |            |     |         |     |
| ------------- | ------------ | --- | ---------- | ---------- | --- | ------- | --- |
|               |              |     | Sequential | Statements |     | in VHDL |     |
Return Statement
This statement is used to terminate the execution of a subprogram.
| Syntax | :             |     |     |     |     |     |     |
| ------ | ------------- | --- | --- | --- | --- | --- | --- |
| return | [expression]; |     |     |     |     |     |     |
For a procedure when this statement is executed, control returns to the point
| at which | the procedure |     | was called. |     |     |     |     |
| -------- | ------------- | --- | ----------- | --- | --- | --- | --- |
return
For a function, the statement returns a value. This value substitutes
| for the          | function | call in | the calling | expression. |       |     |     |
| ---------------- | -------- | ------- | ----------- | ----------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani   |         |             | IC Design   | Group |     | 88  |

| VHDL Tutorial | : Constructs    |     |        |      |     |     |
| ------------- | --------------- | --- | ------ | ---- | --- | --- |
| Example       | :               |     |        |      |     |     |
| function      | AND_Function(X, |     | Y : in | BIT) |     |     |
| return        | BIT is          |     |        |      |     |     |
begin
| if     | X = ’1’ and | Y = ’1’ | then |     |     |     |
| ------ | ----------- | ------- | ---- | --- | --- | --- |
| return | ’1’;        |         |      |     |     |     |
else
| return | ’0’; |     |     |     |     |     |
| ------ | ---- | --- | --- | --- | --- | --- |
| end    | if;  |     |     |     |     |     |
end AND_Function;
. . .
| Z <= | A or AND_Function(C, |     | D); |     |     |     |
| ---- | -------------------- | --- | --- | --- | --- | --- |
. . .
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 89  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

VHDL Tutorial : Usage
Introduction
1.
Overview
2.
Constructs
3.
Usage
4.
Examples
5.
(cid:13)c CEERI, Pilani IC Design Group 90

| VHDL Tutorial | : Usage |     |     |     |
| ------------- | ------- | --- | --- | --- |
Data-Flow Modeling
This style of modeling views the digital system as a network of processing
stages through which the input data (cid:3)ows and gets processed as it (cid:3)ows
| through | them. |     |     |     |
| ------- | ----- | --- | --- | --- |
The main VHDL construct for data-(cid:3)ow modeling is the concurrent signal as-
signment statement. Besides, the concurrent signal assignment statement,
the conditional signal assignment statement and the selected signal assign-
ment statement are used for this style of modeling. The collection of these
concurrent statements models the network of processing stages, with each
statement serving as an abstraction of a processing stage i.e. processing is
data-driven.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 91  |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Usage |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- |
I1
S1
I2
S3
ZOUT
I3
S2
I4
| architecture |     | Data_flow | of NAND4 | is  |     |     |
| ------------ | --- | --------- | -------- | --- | --- | --- |
| signal       | S1, | S2, S3 :  | BIT;     |     |     |     |
begin
| S1 <= | I1     | and I2; |     |     |     |     |
| ----- | ------ | ------- | --- | --- | --- | --- |
| S2 <= | I3     | and I4; |     |     |     |     |
| S3 <= | S1     | and S2; |     |     |     |     |
| ZOUT  | <= not | S3;     |     |     |     |     |
end Data_flow;
The order of statements in the above architecture body is unimportant as they
| are concurrent   |        | statements. |     |           |       |     |
| ---------------- | ------ | ----------- | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |             |     | IC Design | Group | 92  |

| VHDL | Tutorial |     | : Usage |     |     |     |     |     |     |     |
| ---- | -------- | --- | ------- | --- | --- | --- | --- | --- | --- | --- |
Example : Modeling a Multiplexer stage (using conditional signal assignment).
| ZOUT |      | <=   | IN0 | after | 5 ns   |     |     |     |     |     |
| ---- | ---- | ---- | --- | ----- | ------ | --- | --- | --- | --- | --- |
|      |      | when | S1  | = ’0’ | and S0 | =   | ’0’ |     |     |     |
|      | else |      | IN1 | after | 5 ns   |     |     |     |     |     |
|      |      | when | S1  | = ’0’ | and S0 | =   | ’1’ |     |     |     |
|      | else |      | IN2 | after | 5 ns   |     |     |     |     |     |
|      |      | when | S1  | = ’1’ | and S0 | =   | ’0’ |     |     |     |
|      | else |      | IN3 | after | 10 ns; |     |     |     |     |     |
Example : Modeling a Multiplexer stage (using selected signal assignment).
| signal    |        | MUX_Control |     |       | : BIT_vector(1 |      |       | downto    | 0);   |     |
| --------- | ------ | ----------- | --- | ----- | -------------- | ---- | ----- | --------- | ----- | --- |
| with      |        | MUX_Control |     |       | select         |      |       |           |       |     |
|           | ZOUT   | <=          | IN0 | after | 5 ns           | when | "00", |           |       |     |
|           |        |             | IN1 | after | 5 ns           | when | "01", |           |       |     |
|           |        |             | IN2 | after | 5 ns           | when | "10", |           |       |     |
|           |        |             | IN3 | after | 10 ns          | when |       | "11";     |       |     |
| (cid:13)c | CEERI, | Pilani      |     |       |                |      |       | IC Design | Group | 93  |

| VHDL Tutorial | : Usage |     |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- | --- |
VHDL
|     |     |     | Structural | Modeling |     | in  |     |
| --- | --- | --- | ---------- | -------- | --- | --- | --- |
Structural modeling is used to describe the construction of a piece of hardware
in terms of its constituent components and their interconnections.
| The basic | VHDL | constructs | for structural |     | modeling | are : |     |
| --------- | ---- | ---------- | -------------- | --- | -------- | ----- | --- |
(cid:15)
| component          |     | declaration.  |            |     |     |     |     |
| ------------------ | --- | ------------- | ---------- | --- | --- | --- | --- |
| (cid:15) component |     | instantiation | statement. |     |     |     |     |
Component declaration declares the name of a component and its external
| interface        | signals | (cid:151) their | names, | modes     | and   | types. |     |
| ---------------- | ------- | --------------- | ------ | --------- | ----- | ------ | --- |
| (cid:13)c CEERI, | Pilani  |                 |        | IC Design | Group |        | 94  |

| VHDL Tutorial  | : Usage     |      |              |         |       |     |
| -------------- | ----------- | ---- | ------------ | ------- | ----- | --- |
| Example        | : component |      | declaration. |         |       |     |
| component      |             | AND2 |              |         |       |     |
| port(A0,       |             | A1 : | in BIT;      | Z : out | BIT); |     |
| end component; |             |      |              |         |       |     |
Unlike an entity declaration, VHDL does not permit the de(cid:2)nition of an archi-
tecture body for the component. Thus, the component only has an external
interface but no behaviour/internal details. It is like a socket. Component in-
stantiation statement de(cid:2)nes a speci(cid:2)c instance of usage of the component
and connection of its interface signals to signals in the environment e.g. plug-
ging in a socket on the PCB and soldering its pins to the tracks of the PCB.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 95  |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Usage     |                |     |     |     |
| ------------- | ----------- | -------------- | --- | --- | --- |
| Example       | : component | instantiation. |     |     |     |
-- positional association.
| U1 : AND2 | port map(S1, | S2, | S3); |     |     |
| --------- | ------------ | --- | ---- | --- | --- |
or
| -- named  | association. |        |       |     |     |
| --------- | ------------ | ------ | ----- | --- | --- |
| U1 : AND2 | port map(A1  | => S2, | A0 => | S1, |     |
Z => S3);
| (cid:13)c CEERI, | Pilani |     |     | IC Design Group | 96  |
| ---------------- | ------ | --- | --- | --------------- | --- |

| VHDL Tutorial | : Usage |     |     |            |       |         |     |
| ------------- | ------- | --- | --- | ---------- | ----- | ------- | --- |
|               |         |     |     | Structural | Model | Example |     |
I1
S1
U1
I2
S3
U4 ZOUT
U3
I3
S2
U2
I4
A 4-input NAND gate constructed from three 2-input AND gates and one IN-
VERTER.
| entity   | NAND4 | is      |       |         |     |     |     |
| -------- | ----- | ------- | ----- | ------- | --- | --- | --- |
| port(I1, |       | I2, I3, | I4 :  | in BIT; |     |     |     |
|          | ZOUT  | : out   | BIT); |         |     |     |     |
end NAND4;
| architecture     |        | AND2_INVERT |     | of NAND4 | is        |       |     |
| ---------------- | ------ | ----------- | --- | -------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |             |     |          | IC Design | Group | 97  |

| VHDL | Tutorial    |            | : Usage |        |      |      |              |     |       |       |       |     |     |
| ---- | ----------- | ---------- | ------- | ------ | ---- | ---- | ------------ | --- | ----- | ----- | ----- | --- | --- |
| --   | declarative |            |         |        | zone | for  | architecture |     |       |       | items |     |     |
|      | signal      |            | S1,     | S2,    | S3   | :    | BIT;         |     |       |       |       |     |     |
|      | component   |            |         | AND2   |      |      |              |     |       |       |       |     |     |
|      | port(A,     |            |         | B :    | in   | BIT; | C            | :   | out   | BIT); |       |     |     |
|      | end         | component; |         |        |      |      |              |     |       |       |       |     |     |
|      | component   |            |         | INVERT |      |      |              |     |       |       |       |     |     |
|      | port(X      |            | :       | in     | BIT; | Y    | :            | out | BIT); |       |       |     |     |
|      | end         | component; |         |        |      |      |              |     |       |       |       |     |     |
begin
| --               | concurrent    |        |     | statement    |            |         | zone. |        | For  |           | a purely |       |     |
| ---------------- | ------------- | ------ | --- | ------------ | ---------- | ------- | ----- | ------ | ---- | --------- | -------- | ----- | --- |
| --               | structural    |        |     | architecture |            |         |       | only   |      | component |          |       |     |
| --               | instantiation |        |     |              | statements |         |       |        | are  | used.     |          |       |     |
|                  | U1 :          | AND2   |     | port         | map(I1,    |         |       | I2,    | S1); |           |          |       |     |
|                  | U2 :          | AND2   |     | port         | map(I3,    |         |       | I4,    | S2); |           |          |       |     |
|                  | U3 :          | AND2   |     | port         | map(S1,    |         |       | S2,    | S3); |           |          |       |     |
|                  | U4 :          | INVERT |     | port         |            | map(S3, |       | ZOUT); |      |           |          |       |     |
| (cid:13)c CEERI, |               | Pilani |     |              |            |         |       |        |      | IC        | Design   | Group | 98  |

| VHDL Tutorial | : Usage |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- |
end AND2_INVERT;
The above example is a valid VHDL structural model that can be successfully
compiled but not simulated. This is because component instances in the archi-
tecture have no associated behaviour; they merely describe the structure e.g.
| a board | with wired | sockets, | but no | ICs plugged | in. |     |
| ------- | ---------- | -------- | ------ | ----------- | --- | --- |
In order to be able to simulate the model, we need to associate a desired
entity and one of its architecture bodies with each component instance. In
VHDL
parlance it is called con(cid:2)guring a component instance. The con(cid:2)guration
of an architecture body is complete when all the components instances in it
| have | been con(cid:2)gured. |     |     |     |     |     |
| ---- | --------------------- | --- | --- | --- | --- | --- |
Con(cid:2)guration (of component instances and architectures) in VHDL is achieved
| through          | the following | :   |     |                 |     |     |
| ---------------- | ------------- | --- | --- | --------------- | --- | --- |
| (cid:13)c CEERI, | Pilani        |     |     | IC Design Group |     | 99  |

| VHDL Tutorial               | : Usage |     |                     |     |     |     |     |
| --------------------------- | ------- | --- | ------------------- | --- | --- | --- | --- |
| (cid:15) con(cid:2)guration |         |     | speci(cid:2)cation. |     |     |     |     |
(cid:15)
| con(cid:2)guration |     |     | declaration. |     |     |     |     |
| ------------------ | --- | --- | ------------ | --- | --- | --- | --- |
Con(cid:2)guration speci(cid:2)cations are included within the architecture body itself in
| the architecture-item-declaration |     |     |     |     | region. |     |     |
| --------------------------------- | --- | --- | --- | --- | ------- | --- | --- |
Con(cid:2)guration declaration is a separate design unit that is used to hierarchically
| con(cid:2)gure | the | selected |     | architecture |     | of an entity. |     |
| -------------- | --- | -------- | --- | ------------ | --- | ------------- | --- |
Example : Con(cid:2)guring an architecture body through the use of con(cid:2)guration speci(cid:2)cation.
| architecture     |        | AND2_INVERT |          | of NAND4     | is  |              |     |
| ---------------- | ------ | ----------- | -------- | ------------ | --- | ------------ | --- |
| -- declarative   |        |             | zone for | architecture |     | items        |     |
| signal           | S1,    | S2,         | S3 :     | BIT;         |     |              |     |
| (cid:13)c CEERI, | Pilani |             |          |              | IC  | Design Group | 100 |

| VHDL | Tutorial    |            | : Usage |        |                      |            |     |     |       |       |     |     |     |
| ---- | ----------- | ---------- | ------- | ------ | -------------------- | ---------- | --- | --- | ----- | ----- | --- | --- | --- |
|      | component   |            |         | AND2   |                      |            |     |     |       |       |     |     |     |
|      | port(A,     |            |         | B :    | in                   | BIT;       | C   | :   | out   | BIT); |     |     |     |
|      | end         | component; |         |        |                      |            |     |     |       |       |     |     |     |
|      | component   |            |         | INVERT |                      |            |     |     |       |       |     |     |     |
|      | port(X      |            | :       | in     | BIT;                 | Y          | :   | out | BIT); |       |     |     |     |
|      | end         | component; |         |        |                      |            |     |     |       |       |     |     |     |
| --   | configuring |            |         |        | the                  | instances. |     |     |       |       |     |     |     |
| for  | U1,         | U2,        |         | U3     | : AND2               |            |     |     |       |       |     |     |     |
|      |             | use        | entity  |        | TWO_INPUT_AND(Beh1); |            |     |     |       |       |     |     |     |
| for  | U4          | :          | INVERT  |        |                      |            |     |     |       |       |     |     |     |
|      |             | use        | entity  |        | INVERTER(Data_flow); |            |     |     |       |       |     |     |     |
begin
| --               | concurrent    |        |     | statement    |            |     | zone. |      | For  |           | a purely |       |     |
| ---------------- | ------------- | ------ | --- | ------------ | ---------- | --- | ----- | ---- | ---- | --------- | -------- | ----- | --- |
| --               | structural    |        |     | architecture |            |     |       | only |      | component |          |       |     |
| --               | instantiation |        |     |              | statements |     |       |      | are  | used.     |          |       |     |
|                  | U1 :          | AND2   |     | port         | map(I1,    |     |       | I2,  | S1); |           |          |       |     |
| (cid:13)c CEERI, |               | Pilani |     |              |            |     |       |      |      | IC        | Design   | Group | 101 |

| VHDL Tutorial | : Usage |              |          |     |     |     |
| ------------- | ------- | ------------ | -------- | --- | --- | --- |
| U2 :          | AND2    | port map(I3, | I4, S2); |     |     |     |
| U3 :          | AND2    | port map(S1, | S2, S3); |     |     |     |
| U4 :          | INVERT  | port map(S3, | ZOUT);   |     |     |     |
end AND2_INVERT;
Example : con(cid:2)guring and entity and its architecture body through the use of con(cid:2)guration
declaration.
| configuration |             | My_config            | of NAND4 | is  |     |     |
| ------------- | ----------- | -------------------- | -------- | --- | --- | --- |
| for           | AND2_INVERT |                      |          |     |     |     |
| for           | all         | : AND2               |          |     |     |     |
|               | use entity  | TWO_INPUT_AND(Beh1); |          |     |     |     |
| end           | for;        | -- AND2              |          |     |     |     |
| for           | U4 :        | INVERT               |          |     |     |     |
|               | use entity  | INVERTER(Data_flow); |          |     |     |     |
| end           | for;        | -- INVERT            |          |     |     |     |
| end           | for; --     | AND2_INVERT          |          |     |     |     |
end My_config;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 102 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Usage |            |     |         |     |
| ------------- | ------- | ---------- | --- | ------- | --- |
|               |         | Attributes |     | in VHDL |     |
An attribute is a named characteristic of items belonging to the following classes :
| (cid:15) types, | subtypes. |     |     |     |     |
| --------------- | --------- | --- | --- | --- | --- |
(cid:15) procedures, functions.
| (cid:15) signals, | variables, | constants. |           |       |     |
| ----------------- | ---------- | ---------- | --------- | ----- | --- |
| (cid:13)c CEERI,  | Pilani     |            | IC Design | Group | 103 |

| VHDL Tutorial | : Usage |     |     |     |
| ------------- | ------- | --- | --- | --- |
(cid:11) (cid:8)
VHDL
|     | Attributes |     | in  |     |
| --- | ---------- | --- | --- | --- |
(cid:10) (cid:9)
(cid:15) entities, architectures, con(cid:2)gurations, packages.
(cid:15)
components.
(cid:15) statement labels.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 104 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL | Tutorial : Usage |     |     |     |     |     |     |
| ---- | ---------------- | --- | --- | --- | --- | --- | --- |
A particular attribute of a particular item may have a value. In such a case that
| value | may be | referenced | in the | following | manner | :   |     |
| ----- | ------ | ---------- | ------ | --------- | ------ | --- | --- |
item’attribute_identifier
VHDL
has a number of pre-de(cid:2)ned attributes. It also allows user-de(cid:2)ned at-
tributes.
|     |     |     | (cid:11)         |     |            | (cid:8) |     |
| --- | --- | --- | ---------------- | --- | ---------- | ------- | --- |
|     |     |     | Pre-de(cid:2)ned |     | Attributes |         |     |
|     |     |     | (cid:10)         |     |            | (cid:9) |     |
For all scalar subtypes the following attributes are pre-de(cid:2)ned :
| left,            | right, | high, | low |           |       |     |     |
| ---------------- | ------ | ----- | --- | --------- | ----- | --- | --- |
| Example          | :      |       |     |           |       |     |     |
| (cid:13)c CEERI, | Pilani |       |     | IC Design | Group |     | 105 |

| VHDL | Tutorial          | : Usage      |     |          |           |           |        |     |     |
| ---- | ----------------- | ------------ | --- | -------- | --------- | --------- | ------ | --- | --- |
| type | BIT_position      |              |     | is range |           | 15 downto |        | 0;  |     |
| type | FRACTION          |              | is  | range    | -0.999    | to        | 0.999; |     |     |
| For  | the type          | declarations |     |          | as above, |           |        |     |     |
|      | BIT position’left |              |     | is       | 15        |           |        |     |     |
|      | BIT position’low  |              |     | is       | 0         |           |        |     |     |
|      | FRACTION’right    |              |     | is 0.999 |           |           |        |     |     |
FRACTION’high
|        |     |                 |     | is 0.999 |        |     |     |     |     |
| ------ | --- | --------------- | --- | -------- | ------ | --- | --- | --- | --- |
| signal | X   | : BIT_vector(15 |     |          | downto |     | 0); |     |     |
(cid:17)
| X’range |     | 15  | downto | 0   |     |     |     |     |     |
| ------- | --- | --- | ------ | --- | --- | --- | --- | --- | --- |
The construct X’range can be used to specify the range in a looping construct
| such             | as :   |     |     |     |     |           |       |     |     |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group |     | 106 |

| VHDL Tutorial | : Usage      |      |     |     |     |
| ------------- | ------------ | ---- | --- | --- | --- |
| for           | I in X’range | loop |     |     |     |
The event attribute is a pre-de(cid:2)ned attribute of signal class objects.
S’event is a Boolean value which will be TRUE if S has changed value at
| current | simulation | time. |     |     |     |
| ------- | ---------- | ----- | --- | --- | --- |
The event attribute of signals is used to detect transitions of signals in VHDL
code.
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 107 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial |     | : Usage |        |          |     |     |     |     |     |
| ------------- | --- | ------- | ------ | -------- | --- | --- | --- | --- | --- |
| For example,  |     |         | if one | declares |     |     |     |     |     |
| signal        |     | CLOCK   |        | : BIT;   |     |     |     |     |     |
then the following expression can be used in VHDL code to detect the rising
| edge        | of CLOCK |     | :   |     |       |     |     |     |     |
| ----------- | -------- | --- | --- | --- | ----- | --- | --- | --- | --- |
| CLOCK’event |          |     |     | and | CLOCK | =   | ’1’ |     |     |
CLOCK
If the value of this expression is TRUE, then a rising edge of the has
| occurred |     | at the | current |     | simulation |     | time. |     |     |
| -------- | --- | ------ | ------- | --- | ---------- | --- | ----- | --- | --- |
Thus, one can model a positive-edge triggered D (cid:3)ip-(cid:3)op functionality as fol-
| lows             | :      |     |     |     |       |     |           |       |     |
| ---------------- | ------ | --- | --- | --- | ----- | --- | --------- | ----- | --- |
| if (CLOCK’event  |        |     |     | and | CLOCK |     | = ’1’)    | then  |     |
| (cid:13)c CEERI, | Pilani |     |     |     |       |     | IC Design | Group | 108 |

| VHDL Tutorial | : Usage |     |     |     |
| ------------- | ------- | --- | --- | --- |
| Q <=          | D;      |     |     |     |
| end if;       |         |     |     |     |
CLOCK’lastevent is the time value at which the last change in the CLOCK signal
occurred. This can be used to check the setup (or hold) time.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 109 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Usage |             |     |     |             |     |     |            |     |
| ------------- | ------- | ----------- | --- | --- | ----------- | --- | --- | ---------- | --- |
|               |         | Subprograms |     |     | : Functions |     | and | Procedures |     |
A subprogram de(cid:2)nes a sequential algorithm that performs a certain compu-
| tation. | There | are | two kinds | of subprograms |     |     | :   |     |     |
| ------- | ----- | --- | --------- | -------------- | --- | --- | --- | --- | --- |
(cid:15) Function is usually used to describe often-used computation that returns
| a   | single | value. | It executes |     | in zero | simulation |     | time. |     |
| --- | ------ | ------ | ----------- | --- | ------- | ---------- | --- | ----- | --- |
Common uses are as a resolution function and for type conversion func-
tions.
(cid:15)
Procedure is usually used to partition large behavioural descriptions into
modular sections. It can return zero or more values. A procedure may or
may not execute in zero simulation time, depending on whether it has a
wait
|                  | statement |     | or not. |     |           |       |     |     |     |
| ---------------- | --------- | --- | ------- | --- | --------- | ----- | --- | --- | --- |
| (cid:13)c CEERI, | Pilani    |     |         |     | IC Design | Group |     |     | 110 |

| VHDL | Tutorial : Usage |          |     |           |     |
| ---- | ---------------- | -------- | --- | --------- | --- |
|      |                  | Packages | and | Libraries |     |
Package declaration and the associated package body are respectively pri-
| mary | and secondary | design | units. |     |     |
| ---- | ------------- | ------ | ------ | --- | --- |
The package declaration and associated package body are a means of shar-
ing a set of declarations and any associated de(cid:2)ning bodies among multiple
| design | units (without | having | to re-declare | them). |     |
| ------ | -------------- | ------ | ------------- | ------ | --- |
A set of declarations and associated de(cid:2)ning bodies are encapsulated as a
package declaration (cid:150) package body pair. This pair is analysed and stored in
a design library. At the desired places in the VHDL code, the library and the
speci(cid:2)c package(s) therein can be made visible to VHDL code, thus obviating
| the              | need for their | repetition. |           |       |     |
| ---------------- | -------------- | ----------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani         |             | IC Design | Group | 111 |

| VHDL Tutorial | : Usage |     |     |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- | --- | --- |
(cid:11) (cid:8)
|     |     |     |     | Packages |     | and Libraries |     |     |
| --- | --- | --- | --- | -------- | --- | ------------- | --- | --- |
(cid:10) (cid:9)
| package  | My_Pack    |           | is    |        |          |       |       |     |
| -------- | ---------- | --------- | ----- | ------ | -------- | ----- | ----- | --- |
| type     | COLOR      | is        | (red, | green, | yellow); |       |       |     |
| type     | VLOG_LOGIC |           | is    | (’X’,  | ’0’,     | ’1’,  | ’Z’); |     |
| constant |            | Rise_Time |       | : TIME | :=       | 5 ns; |       |     |
| constant |            | Fall_Time |       | : TIME | :=       | 3 ns; |       |     |
| end      | My_Pack;   |           |       |        |          |       |       |     |
The above package declaration needs no package body. It is self-contained in
| terms            | of necessary |     | de(cid:2)nitions/details. |     |           |       |     |     |
| ---------------- | ------------ | --- | ------------------------- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani       |     |                           |     | IC Design | Group |     | 112 |

| VHDL Tutorial    | : Usage |          |               |           |               |         |     |
| ---------------- | ------- | -------- | ------------- | --------- | ------------- | ------- | --- |
|                  |         |          | (cid:11)      |           |               | (cid:8) |     |
|                  |         |          | Packages      |           | and Libraries |         |     |
|                  |         |          | (cid:10)      |           |               | (cid:9) |     |
| The following    |         | example  | shows         | the use   | of package    | body.   |     |
| package          | My_FUNC |          | is            |           |               |         |     |
| constant         |         | DELAY    | : TIME;       |           |               |         |     |
| function         |         | PARITY(A | : BIT_vector) |           | return        | BIT;    |     |
| end My_FUNC;     |         |          |               |           |               |         |     |
| (cid:13)c CEERI, | Pilani  |          |               | IC Design | Group         |         | 113 |

| VHDL    | Tutorial |      | : Usage  |         |         |               |       |     |            |     |                |     |
| ------- | -------- | ---- | -------- | ------- | ------- | ------------- | ----- | --- | ---------- | --- | -------------- | --- |
| Note    |          | that | only     | one     | package |               | body  |     | is allowed |     | for a package. |     |
| package |          | body |          | My_FUNC |         | is            |       |     |            |     |                |     |
|         | constant |      | DELAY    |         | : TIME  | :=            | 2 ns; |     |            |     |                |     |
|         | function |      | PARITY(A |         |         | : BIT_vector) |       |     |            |     |                |     |
|         | return   |      | BIT      | is      |         |               |       |     |            |     |                |     |
|         | variable |      |          | X :     | BIT     | := ’0’;       |       |     |            |     |                |     |
begin
|     | for    | i       | in    | A’range |      | loop |     |     |     |     |     |     |
| --- | ------ | ------- | ----- | ------- | ---- | ---- | --- | --- | --- | --- | --- | --- |
|     |        | if      | (A(i) | =       | ’1’) | then |     |     |     |     |     |     |
|     |        | X       | :=    | not(X); |      |      |     |     |     |     |     |     |
|     |        | end     | if;   |         |      |      |     |     |     |     |     |     |
|     | end    | loop;   |       |         |      |      |     |     |     |     |     |     |
|     | return |         | X;    |         |      |      |     |     |     |     |     |     |
|     | end    | PARITY; |       |         |      |      |     |     |     |     |     |     |
end My_FUNC;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     |     | IC  | Design | Group |     | 114 |
| ---------------- | --- | ------ | --- | --- | --- | --- | --- | --- | ------ | ----- | --- | --- |

| VHDL | Tutorial | : Usage |     |     |     |     |          |     |     |               |     |     |
| ---- | -------- | ------- | --- | --- | --- | --- | -------- | --- | --- | ------------- | --- | --- |
|      |          |         |     |     | Use | of  | Packages |     |     | and Libraries |     |     |
Within a design unit in the VHDL design (cid:2)le (the design (cid:2)le comprises of a
collection of design units), visibility of items contained in a package that has
been analyzed into a design library can be achieved (or effected) by placing
|            | library |        |         | use   |          |     |        |          |     |        |       |     |
| ---------- | ------- | ------ | ------- | ----- | -------- | --- | ------ | -------- | --- | ------ | ----- | --- |
| the        |         |        | and     |       | clauses  |     | before |          | the | design | unit. |     |
| library    | work;   |        |         |       |          |     |        |          |     |        |       |     |
| -- work    | is      | the    | default |       | library. |     |        | The      |     |        |       |     |
| -- library |         | clause |         | above |          | can | be     | dropped. |     |        |       |     |
use work.My_FUNC.all;
| . .     | . entity |     | declaration |     |     | . . | .   |     |     |     |     |     |
| ------- | -------- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| library | CMOS;    |     |             |     |     |     |     |     |     |     |     |     |
use CMOS.NOR2;
| . .              | . entity     |     | declaration |      |     | or  |     |     |        |       |     |     |
| ---------------- | ------------ | --- | ----------- | ---- | --- | --- | --- | --- | ------ | ----- | --- | --- |
|                  | architecture |     |             | body |     | . . | .   |     |        |       |     |     |
| (cid:13)c CEERI, | Pilani       |     |             |      |     |     |     | IC  | Design | Group |     | 115 |

| VHDL Tutorial | : Usage |     |     |       |           |     |     |     |
| ------------- | ------- | --- | --- | ----- | --------- | --- | --- | --- |
|               |         |     |     | Block | Statement |     |     |     |
Block statement is a concurrent statement. By itself it has no execution seman-
tics, rather it provides additional semantics for statements that are enclosed
| within          | it.     |          |               |          |           |           |        |     |
| --------------- | ------- | -------- | ------------- | -------- | --------- | --------- | ------ | --- |
| It is primarily |         | used for | the following |          | purposes  | :         |        |     |
| 1. To           | disable | signal   | drivers       | by using | guards.   |           |        |     |
| 2. To           | create  | an item  | declaration   |          | zone with | a limited | scope. |     |
3. To demarcate a portion of the design or a level in design hierarchy.
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design Group |     |     | 116 |
| ---------------- | ------ | --- | --- | --- | --------------- | --- | --- | --- |

| VHDL Tutorial | : Usage    |        |         |     |     |     |
| ------------- | ---------- | ------ | ------- | --- | --- | --- |
| Block         | statements | can be | nested. |     |     |     |
Any number of concurrent statements (including none) can appear within a
block.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 117 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Usage |         |                      |     |     |      |     |
| ------------- | ------- | ------- | -------------------- | --- | --- | ---- | --- |
| Syntax        | :       |         |                      |     |     |      |     |
| block-label   |         | : block | [(guard-expression)] |     |     | [is] |     |
[block-header]
[block-declarations]
begin
[concurrent-statements]
| end block | [block-label]; |     |     |     |     |     |     |
| --------- | -------------- | --- | --- | --- | --- | --- | --- |
The block-header describes the interface of the block statement to its envi-
| ronment | (to | be discussed | later). |     |     |     |     |
| ------- | --- | ------------ | ------- | --- | --- | --- | --- |
The block-declarations are visible only within the block i.e. between block
| ...              | end block. |     |     |           |       |     |     |
| ---------------- | ---------- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani     |     |     | IC Design | Group |     | 118 |

| VHDL Tutorial | : Usage |     |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- | --- |
guard-expression
If a appears in a block statement, an implicit declaration of
a signal named GUARD of type Boolean occurs within the block. The value of
the GUARD signal is always updated to re(cid:3)ect the value of the guard expression
(the guard-expression must always be of type Boolean). Signal assignment
statements appearing within the block statement can use this GUARD signal to
| enable     | or disable |         | their drivers. |       |          |         |     |
| ---------- | ---------- | ------- | -------------- | ----- | -------- | ------- | --- |
| Example:   | A          | gated   | inverter.      |       |          |         |     |
| -- guarded |            | signal  | assignment     | to an | ordinary | signal. |     |
| Binv       | : block    | (ENABLE | = ’1’)         |       |          |         |     |
begin
| Z <=      | guarded | (not | A); |     |     |     |     |
| --------- | ------- | ---- | --- | --- | --- | --- | --- |
| end block | Binv;   |      |     |     |     |     |     |
The concurrent signal assignment to Z with keyword guarded preceding it is
called the guarded assignment. Guarded assignments are the only concurrent
statements whose semantics are affected by the enclosing block statement.
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design Group |     | 119 |
| ---------------- | ------ | --- | --- | --- | --------------- | --- | --- |

| VHDL | Tutorial : Usage |     |     |     |     |     |     |     |
| ---- | ---------------- | --- | --- | --- | --- | --- | --- | --- |
A guarded assignment is sensitive to signal GUARD and all the signals that
| appear | in the | expression | following | the   | keyword | guarded. |     |     |
| ------ | ------ | ---------- | --------- | ----- | ------- | -------- | --- | --- |
|        |        | GUARD      |           | TRUE, |         |          | not | A   |
If the value of the signal is then the value of expression is
assigned to the target signal Z, otherwise the value of the expression does not
|     |     |     |     | Z,  | Z   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
affect the value of the target signal and continues to be driven with the old
| value | of (not | A). |     |     |     |     |     |     |
| ----- | ------- | --- | --- | --- | --- | --- | --- | --- |
Every guarded assignment has an equivalent process statement. Here is an
| example | :                        |        |     |     |     |     |     |     |
| ------- | ------------------------ | ------ | --- | --- | --- | --- | --- | --- |
| BG :    | block (guard-expression) |        |     |     |     |     |     |     |
| signal  | SIG                      | : BIT; |     |     |     |     |     |     |
begin
| SIG | <= guarded | waveform-elements; |     |     |     |     |     |     |
| --- | ---------- | ------------------ | --- | --- | --- | --- | --- | --- |
| end | block BG;  |                    |     |     |     |     |     |     |
The equivalent process statement for the guarded assignment is :
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     |     | 120 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- | --- |

| VHDL      | Tutorial | : Usage |                    |          |     |             |     |     |     |     |
| --------- | -------- | ------- | ------------------ | -------- | --- | ----------- | --- | --- | --- | --- |
| BG :      | block    |         | (guard-expression) |          |     |             |     |     |     |     |
| -- signal |          | GUARD   | :                  | Boolean; |     | -- implicit |     |     |     |     |
| signal    |          | SIG     | : BIT;             |          |     |             |     |     |     |     |
begin
| -- GUARD |     | <=  | guard-expression; |     |     | --  | implicit |     |     |     |
| -------- | --- | --- | ----------------- | --- | --- | --- | -------- | --- | --- | --- |
process
begin
|      | if       | GUARD                            | then               |     |     |     |     |     |        |     |
| ---- | -------- | -------------------------------- | ------------------ | --- | --- | --- | --- | --- | ------ | --- |
|      | SIG      | <=                               | waveform-elements; |     |     |     |     |     |        |     |
|      | end      | if;                              |                    |     |     |     |     |     |        |     |
| wait |          | on signals-in-waveform-elements, |                    |     |     |     |     |     | GUARD; |     |
| end  | process; |                                  |                    |     |     |     |     |     |        |     |
| end  | block    | BG;                              |                    |     |     |     |     |     |        |     |
Though the signal named GUARD is implicitly declared in the block statement
with a guard expression, it can be used explicitly in the block statement.
GUARD
| Example          |       | : Explicit |        | use of | signal |     |           | .   |        |     |
| ---------------- | ----- | ---------- | ------ | ------ | ------ | --- | --------- | --- | ------ | --- |
| B2 :             | block |            | (CLEAR | =      | ’0’    | and | PRESET    |     | = ’1’) |     |
| (cid:13)c CEERI, |       | Pilani     |        |        |        |     | IC Design |     | Group  | 121 |

| VHDL Tutorial | : Usage |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- |
begin
| Q <=      | ’1’ when | not GUARD |     | else ’0’; |     |     |
| --------- | -------- | --------- | --- | --------- | --- | --- |
| end block | B2;      |           |     |           |     |     |
Example : Explicit declaration of GUARD signal in the block and its use in
| guarded | assignment. |            |     |     |     |     |
| ------- | ----------- | ---------- | --- | --- | --- | --- |
| B3 :    | block       |            |     |     |     |     |
| signal  | GUARD       | : Boolean; |     |     |     |     |
begin
| GUARD     | <= CLEAR | = ’0’ | and | PRESET | = ’1’; |     |
| --------- | -------- | ----- | --- | ------ | ------ | --- |
| Q <=      | guarded  | DIN;  |     |        |        |     |
| end block | B3;      |       |     |        |        |     |
Example : Level-sensitive (active-high) latch using block statement with a
guard.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 122 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL         | Tutorial | : Usage |             |      |      |          |       |     |
| ------------ | -------- | ------- | ----------- | ---- | ---- | -------- | ----- | --- |
| entity       |          | LATCH   | is          |      |      |          |       |     |
| port(D,      |          | CLOCK   |             | : in | BIT; | Q : out  | BIT); |     |
| end          | LATCH;   |         |             |      |      |          |       |     |
| architecture |          |         | LATCH_BLOCK |      |      | of LATCH | is    |     |
begin
| L1  | :   | block | (CLOCK’event |     |     | and CLOCK | = ’1’) |     |
| --- | --- | ----- | ------------ | --- | --- | --------- | ------ | --- |
begin
|     | Q            | <= guarded |     | D;  |     |     |     |     |
| --- | ------------ | ---------- | --- | --- | --- | --- | --- | --- |
| end |              | block      | L1; |     |     |     |     |     |
| end | LATCH_BLOCK; |            |     |     |     |     |     |     |
Example : Edge-sensitive (positive-edge triggered) (cid:3)ip-(cid:3)op using block state-
| ment             | with | a guard. |     |     |     |           |       |     |
| ---------------- | ---- | -------- | --- | --- | --- | --------- | ----- | --- |
| entity           |      | DFF is   |     |     |     |           |       |     |
| (cid:13)c CEERI, |      | Pilani   |     |     |     | IC Design | Group | 123 |

| VHDL         | Tutorial | :   | Usage |           |     |     |      |     |     |     |       |     |     |
| ------------ | -------- | --- | ----- | --------- | --- | --- | ---- | --- | --- | --- | ----- | --- | --- |
| port(D,      |          |     | CLOCK |           | :   | in  | BIT; |     | Q : | out | BIT); |     |     |
| end          | DFF;     |     |       |           |     |     |      |     |     |     |       |     |     |
| architecture |          |     |       | DFF_BLOCK |     |     | of   |     | DFF | is  |       |     |     |
begin
| L2  | :   | block(CLOCK |     |     |     | =   | ’1’ | and |     | not | CLOCK’stable) |     |     |
| --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- |
begin
|     | Q          | <=    | guarded |     | D;  |     |     |     |     |     |     |     |     |
| --- | ---------- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| end |            | block |         | l2; |     |     |     |     |     |     |     |     |     |
| end | DFF_BLOCK; |       |         |     |     |     |     |     |     |     |     |     |     |
(cid:11) (cid:8)
|     |     |     |     |     |     | Guarded |     |     | vs. | Ordinary |     | Signals |     |
| --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | -------- | --- | ------- | --- |
(cid:10) (cid:9)
VHDL permits declaration of guarded signals of two different kinds using the
register bus
usual signal declarations appended with either the keyword or
| just             | before |        | the       | ; that |     | terminates |      |     | the | declaration. |            |       |     |
| ---------------- | ------ | ------ | --------- | ------ | --- | ---------- | ---- | --- | --- | ------------ | ---------- | ----- | --- |
| Note             | that   |        | a guarded |        |     | signal     | must |     | be  | of           | a resolved | type. |     |
| (cid:13)c CEERI, |        | Pilani |           |        |     |            |      |     | IC  | Design       | Group      |       | 124 |

| VHDL Tutorial | : Usage      |     |            |           |          |           |     |     |
| ------------- | ------------ | --- | ---------- | --------- | -------- | --------- | --- | --- |
| Example       | :            |     |            |           |          |           |     |     |
| signal        | GUARD_SIG    |     | :          | Wired_AND | BIT      | register; |     |     |
| signal        | GUARD_A      |     | : Wired_OR |           | BIT bus; |           |     |     |
| signal        | ORDINARY_SIG |     |            | : BIT;    |          |           |     |     |
A guarded signal behaves differently (from an ordinary signal) when assigned
| to by | a guarded |     | assignment. |     |     |     |     |     |
| ----- | --------- | --- | ----------- | --- | --- | --- | --- | --- |
When the implicitly declared signal GUARD becomes FALSE, the driver of the
guarded assignment disconnects from the target guarded signal i.e. it does
not participate in the resolution of the guarded signal’s value (contrast this with
the case of an ordinary signal where under a similar circumstance the driver
continues to drive the old value of the signal). In case of a guarded signal a
disconnection speci(cid:2)cation can be used to specify the delay after which the
GUARD FALSE.
| driver           | of the | signal | will | disconnect | once      | signal | becomes |     |
| ---------------- | ------ | ------ | ---- | ---------- | --------- | ------ | ------- | --- |
| (cid:13)c CEERI, | Pilani |        |      |            | IC Design | Group  |         | 125 |

| VHDL       | Tutorial :  | Usage               |               |                     |                    |       |      |     |
| ---------- | ----------- | ------------------- | ------------- | ------------------- | ------------------ | ----- | ---- | --- |
| The        | syntax      | of the              | disconnection |                     | speci(cid:2)cation |       | is : |     |
| disconnect |             | guarded-signal-name |               |                     |                    | :     |      |     |
|            | signal-type |                     | after         | time-expression;    |                    |       |      |     |
| Example    |             | : Disconnection     |               | speci(cid:2)cation. |                    |       |      |     |
| disconnect |             | GUARD_SIG           |               | : BIT               | after              | 5 ns; |      |     |
If no disconnection time is speci(cid:2)ed for a guarded signal then, by default, one
| delta | delay | is presumed. |     |     |     |     |     |     |
| ----- | ----- | ------------ | --- | --- | --- | --- | --- | --- |
The two guarded signal kinds (cid:151) bus and register (cid:151) differ in the manner in
which the value of the signal is determined when all the drivers of the signal
are disconnected. For a guarded signal of kind bus, the resolution function is
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group |     | 126 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- | --- |

| VHDL Tutorial |     | : Usage |     |     |     |     |     |     |     |     |
| ------------- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
still called in to resolve the value of the signal, whereas for a guarded signal of
kind register the resolution function is not called and the value driven by the
last driver before it disconnected is maintained for the signal. These properties
make the two guarded signal kinds imitate the behaviour of their corresponding
| hardware |     | namesakes. |     |             |     |     |            |     |          |     |
| -------- | --- | ---------- | --- | ----------- | --- | --- | ---------- | --- | -------- | --- |
| Example  |     | : Guarded  |     | assignments |     |     | to guarded |     | signals. |     |
use work.MY_PACK.all;
| -- package   |         | MY_PACK |      | contains  |     | functions, |     |     |     |     |
| ------------ | ------- | ------- | ---- | --------- | --- | ---------- | --- | --- | --- | --- |
| -- Wired_AND |         |         | and  | Wired_OR. |     |            |     |     |     |     |
| entity       | EXAMPLE |         | is   |           |     |            |     |     |     |     |
| port(CLOCK   |         |         | : in | BIT;      | D : | in BIT);   |     |     |     |     |
end EXAMPLE;
| architecture     |        |         | GUARDED_SIGNAL |             |     | of  | EXAMPLE   | is    |     |     |
| ---------------- | ------ | ------- | -------------- | ----------- | --- | --- | --------- | ----- | --- | --- |
| signal           |        | REG_SIG |                | : Wired_AND |     | BIT | register; |       |     |     |
| (cid:13)c CEERI, | Pilani |         |                |             |     |     | IC Design | Group |     | 127 |

| VHDL | Tutorial   |     | : Usage |     |          |     |       |          |     |     |
| ---- | ---------- | --- | ------- | --- | -------- | --- | ----- | -------- | --- | --- |
|      | signal     |     | BUS_SIG | :   | Wired_OR |     |       | BIT bus; |     |     |
|      | disconnect |     | REG_SIG |     | :        | BIT | after | 10 ns;   |     |     |
|      | disconnect |     | BUS_SIG |     | :        | BIT | after | 10 ns;   |     |     |
begin
|     | BX :   | block |       |     |     |               |     |     |     |     |
| --- | ------ | ----- | ----- | --- | --- | ------------- | --- | --- | --- | --- |
|     | (CLOCK |       | = ’1’ | and | not | CLOCK’stable) |     |     |     |     |
begin
|     | REG_SIG |       | <=  | guarded |     | D after |     | 5 ns; |     |     |
| --- | ------- | ----- | --- | ------- | --- | ------- | --- | ----- | --- | --- |
|     | BUS_SIG |       | <=  | guarded |     | D after |     | 5 ns; |     |     |
|     | end     | block | BX; |         |     |         |     |       |     |     |
end EXAMPLE;
Example: Use of block statement at elaboration time of a VHDL compiler.
| architecture     |                    |        | DUMMY    |     | of DUMMY  |     | is  |           |       |     |
| ---------------- | ------------------ | ------ | -------- | --- | --------- | --- | --- | --------- | ----- | --- |
| component        |                    |        | NOR_GATE |     |           |     |     |           |       |     |
|                  | generic(RISE_TIME, |        |          |     | FALL_TIME |     |     | : TIME);  |       |     |
| (cid:13)c CEERI, |                    | Pilani |          |     |           |     |     | IC Design | Group | 128 |

| VHDL Tutorial |     | : Usage |      |     |      |         |       |     |     |
| ------------- | --- | ------- | ---- | --- | ---- | ------- | ----- | --- | --- |
| port(S0,      |     |         | S1 : | in  | BIT; | Q : out | BIT); |     |     |
end component;
| component |     | AND2_GATE |       |      |     |          |              |     |     |
| --------- | --- | --------- | ----- | ---- | --- | -------- | ------------ | --- | --- |
| port(DOUT |     |           | : out | BIT; |     | DIN : in | BIT_vector); |     |     |
end component;
| for N1, |         | N2          | : NOR_GATE              |      |     |             |     |     |     |
| ------- | ------- | ----------- | ----------------------- | ---- | --- | ----------- | --- | --- | --- |
| use     | entity  |             | work.NOR2(NOR2_DELAYS); |      |     |             |     |     |     |
| generic |         | map(PT_HL   |                         |      | =>  | FALL_TIME,  |     |     |     |
|         |         |             | PT_LH                   |      | =>  | RISE_TIME); |     |     |     |
| port    | map(S0, |             | S1,                     |      | Q); |             |     |     |     |
| for all |         | : AND2_GATE |                         |      |     |             |     |     |     |
| use     | entity  |             | work.AND2(GENERIC_EX);  |      |     |             |     |     |     |
| generic |         | map(10);    |                         |      |     |             |     |     |     |
| port    | map(A   |             | =>                      | DIN, | Z   | => DOUT);   |     |     |     |
| signal  | WR,     |             | RD, RW,                 |      | S1, | S2 : BIT;   |     |     |     |
| signal  | SA      | :           | BIT_vector(1            |      |     | to 10);     |     |     |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     | IC Design | Group | 129 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial  | : Usage |          |       |     |     |     |     |
| -------------- | ------- | -------- | ----- | --- | --- | --- | --- |
| N1 : NOR_GATE  |         |          |       |     |     |     |     |
| generic        | map(2   | ns,      | 3 ns) |     |     |     |     |
| port           | map(WR, | RD, RW); |       |     |     |     |     |
| A1 : AND2_GATE |         |          |       |     |     |     |     |
| port           | map(S1, | SA);     |       |     |     |     |     |
| N2 : NOR_GATE  |         |          |       |     |     |     |     |
| generic        | map(4   | ns,      | 6 ns) |     |     |     |     |
| port           | map(S1, | SA(2),   | S3);  |     |     |     |     |
end DUMMY;
The above structural architecture on elaboration will get translated into :
| N1 : blocka        |        |               |     |                |           |       |     |
| ------------------ | ------ | ------------- | --- | -------------- | --------- | ----- | --- |
| -- block           | for    | the component |     | instantiation. |           |       |     |
| generic(RISE_TIME, |        | FALL_TIME     |     | :              | TIME);    |       |     |
| (cid:13)c CEERI,   | Pilani |               |     |                | IC Design | Group | 130 |

| VHDL Tutorial |               | : Usage      |           |      |            |             |            |         |     |     |
| ------------- | ------------- | ------------ | --------- | ---- | ---------- | ----------- | ---------- | ------- | --- | --- |
| -- The        | generics      |              | of        | the  |            | block       | correspond |         | to  |     |
| -- the        | declaration   |              |           | of   | generics   |             |            | in the  |     |     |
| -- component  |               | declaration. |           |      |            |             |            |         |     |     |
| generic       | map(RISE_TIME |              |           |      | =>         | 2           | ns,        |         |     |     |
|               |               | FALL_TIME    |           |      | =>         | 3           | ns);       |         |     |     |
| -- Mapping    |               | of           | generics  |      |            | from        |            |         |     |     |
| -- component  |               | to           | instance  |      |            |             |            |         |     |     |
| port(S0,      |               | S1 :         | in        | BIT; | Q          | : out       | BIT);      |         |     |     |
| -- ports      |               | of the       | block     |      | correspond |             |            | to the  |     |     |
| -- ports      |               | in the       | component |      |            | declaration |            |         |     |     |
| port          | map(S0        | =>           | WR,       | S1   | =>         | RD,         | Q          | => RW); |     |     |
| -- Mapping    |               | of           | ports     |      | from       |             |            |         |     |     |
| -- component  |               | to           | instance  |      |            |             |            |         |     |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     |     | IC Design | Group | 131 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial    |          | : Usage      |       |       |            |             |        |       |     |
| ---------------- | -------- | ------------ | ----- | ----- | ---------- | ----------- | ------ | ----- | --- |
| NOR2             | : block  |              |       |       |            |             |        |       |     |
| -- A             | block    | for          | the   | bound |            |             |        |       |     |
| -- entity’s      |          | architecture |       |       |            |             |        |       |     |
| generic(PT_HL,   |          |              | PT_LH |       | : TIME);   |             |        |       |     |
| -- generics      |          | of           | the   | block | correspond |             | to     |       |     |
| -- the           | generics |              | in    | the   | entity     | declaration |        |       |     |
| (cid:13)c CEERI, | Pilani   |              |       |       |            | IC          | Design | Group | 132 |

| VHDL Tutorial |           | : Usage |           |        |             |     |       |        |     |     |
| ------------- | --------- | ------- | --------- | ------ | ----------- | --- | ----- | ------ | --- | --- |
| generic       | map(PT_HL |         |           | =>     | FALL_TIME,  |     |       |        |     |     |
|               |           |         | PT_LH     | =>     | RISE_TIME); |     |       |        |     |     |
| -- Mapping    |           | of      | generics  |        | from        |     |       |        |     |     |
| -- entity     |           | to      | component |        |             |     |       |        |     |     |
| port(A,       | B         | :       | in BIT;   |        | Z : out     |     | BIT); |        |     |     |
| -- ports      |           | of      | the       | block  | correspond  |     |       | to the |     |     |
| -- ports      |           | in      | the       | entity | declaration |     |       |        |     |     |
| port map(A    |           | =>      | S0,       | B      | => S1,      | Z   | =>    | Q);    |     |     |
| -- Mapping    |           | of      | ports     |        | from        |     |       |        |     |     |
| -- entity     |           | to      | component |        |             |     |       |        |     |     |
begin
| -- statements    |        |      | in    | architecture |     |     | body |           |       |     |
| ---------------- | ------ | ---- | ----- | ------------ | --- | --- | ---- | --------- | ----- | --- |
| -- appear        |        | here |       |              |     |     |      |           |       |     |
| end              | block  |      | NOR2; |              |     |     |      |           |       |     |
| end block        |        | N1;  |       |              |     |     |      |           |       |     |
| (cid:13)c CEERI, | Pilani |      |       |              |     |     |      | IC Design | Group | 133 |

| VHDL Tutorial |           | : Usage |           |        |             |     |       |        |     |     |
| ------------- | --------- | ------- | --------- | ------ | ----------- | --- | ----- | ------ | --- | --- |
| generic       | map(PT_HL |         |           | =>     | FALL_TIME,  |     |       |        |     |     |
|               |           |         | PT_LH     | =>     | RISE_TIME); |     |       |        |     |     |
| -- Mapping    |           | of      | generics  |        | from        |     |       |        |     |     |
| -- entity     |           | to      | component |        |             |     |       |        |     |     |
| port(A,       | B         | :       | in BIT;   |        | Z : out     |     | BIT); |        |     |     |
| -- ports      |           | of      | the       | block  | correspond  |     |       | to the |     |     |
| -- ports      |           | in      | the       | entity | declaration |     |       |        |     |     |
| port map(A    |           | =>      | S0,       | B      | => S1,      | Z   | =>    | Q);    |     |     |
| -- Mapping    |           | of      | ports     |        | from        |     |       |        |     |     |
| -- entity     |           | to      | component |        |             |     |       |        |     |     |
begin
| -- statements    |        |      | in    | architecture |     |     | body |           |       |     |
| ---------------- | ------ | ---- | ----- | ------------ | --- | --- | ---- | --------- | ----- | --- |
| -- appear        |        | here |       |              |     |     |      |           |       |     |
| end              | block  |      | NOR2; |              |     |     |      |           |       |     |
| end block        |        | N1;  |       |              |     |     |      |           |       |     |
| (cid:13)c CEERI, | Pilani |      |       |              |     |     |      | IC Design | Group | 134 |

| VHDL Tutorial | :   | Usage |     |          |     |           |     |     |
| ------------- | --- | ----- | --- | -------- | --- | --------- | --- | --- |
|               |     |       |     | Generate |     | Statement |     |     |
Concurrent statements can be conditionally selected or replicated during the
| elaboration |     | phase     | using | the generate |     | statement. |     |     |
| ----------- | --- | --------- | ----- | ------------ | --- | ---------- | --- | --- |
| There       | are | two forms | of    | the generate |     | statement  | :   |     |
1. For-generation scheme : for replicating concurrent statements using a for-
|     | loop like | scheme. |     |     |     |     |     |     |
| --- | --------- | ------- | --- | --- | --- | --- | --- | --- |
2. If-generation scheme : for conditionally elaborating concurrent statements.
The generate statement is interpreted during elaboration. It has no simulation
semantics. It resembles a macro expansion and provides a compact descrip-
tion of regular structures like memories, registers and counters.
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group |     | 135 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- | --- |

| VHDL Tutorial  | : Usage             |         |                   |     |     |
| -------------- | ------------------- | ------- | ----------------- | --- | --- |
| Syntax         | (for-generation     | scheme) | :                 |     |     |
| generate-label |                     | :       |                   |     |     |
| for            | generate-identifier |         | in discrete-range |     |     |
generate
[block-declarations
begin]
concurrent-statements
| end generate |         | [generate-label]; |         |     |     |
| ------------ | ------- | ----------------- | ------- | --- | --- |
| Example      | : Using | for-generation    | scheme. |     |     |
|              |         |                   | A       | B   |     |
4 4
COUT CIN
FULL_ADD4
4
SUM
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 136 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL    | Tutorial |           | : Usage |              |     |           |        |           |       |           |        |        |           |        |     |
| ------- | -------- | --------- | ------- | ------------ | --- | --------- | ------ | --------- | ----- | --------- | ------ | ------ | --------- | ------ | --- |
|         |          |           |         |              |     | A(3) B(3) |        | A(2) B(2) |       | A(1) B(1) |        |        | A(0) B(0) |        |     |
|         |          |           |         | CAR(4)       |     |           | CAR(3) |           |       | CAR(2)    |        | CAR(1) |           | CAR(0) |     |
|         |          |           |         |              |     | FA(3)     |        |           | FA(2) |           | FA(1)  |        | FA(0)     |        |     |
|         |          |           |         | COUT         |     |           |        |           |       |           |        |        |           | CIN    |     |
|         |          |           |         |              |     | SUM(3)    |        | SUM(2)    |       |           | SUM(1) |        | SUM(0)    |        |     |
| entity  |          | FULL_ADD4 |         | is           |     |           |        |           |       |           |        |        |           |        |     |
| port(A, |          | B         | : in    | BIT_vector(3 |     |           | downto |           | 0);   |           |        |        |           |        |     |
|         |          | CIN       | : in    | BIT;         |     |           |        |           |       |           |        |        |           |        |     |
|         |          | SUM       | : out   | BIT_vector(3 |     |           | downto |           | 0);   |           |        |        |           |        |     |
|         |          | COUT      | : out   | BIT);        |     |           |        |           |       |           |        |        |           |        |     |
end FULL_ADD4;
| architecture     |           |            |            | FOR_GENERATE   |     |         | of FULL_ADD4 |     |           | is    |     |     |     |     |     |
| ---------------- | --------- | ---------- | ---------- | -------------- | --- | ------- | ------------ | --- | --------- | ----- | --- | --- | --- | --- | --- |
|                  | component |            | FULL_ADDER |                |     |         |              |     |           |       |     |     |     |     |     |
|                  | port(PA,  |            |            | PB, PC         | :   | in BIT; |              |     |           |       |     |     |     |     |     |
|                  |           |            | PSUM,      | PCOUT:         |     | out     | BIT);        |     |           |       |     |     |     |     |     |
|                  | end       | component; |            |                |     |         |              |     |           |       |     |     |     |     |     |
|                  | signal    |            | CAR        | : BIT_vector(4 |     |         | downto       |     | 0);       |       |     |     |     |     |     |
| (cid:13)c CEERI, |           | Pilani     |            |                |     |         |              |     | IC Design | Group |     |     |     |     | 137 |

| VHDL Tutorial | : Usage |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- |
begin
| CAR(0) | <=           | CIN;          |                |            |     |     |
| ------ | ------------ | ------------- | -------------- | ---------- | --- | --- |
| GK     | : for        | K in 3 downto | 0              | generate   |     |     |
| FA     | : FULL_ADDER |               | port map(A(K), |            |     |     |
|        | B(K),        | CAR(K),       | SUM(K),        | CAR(K+1)); |     |     |
| end    | generate     | GK;           |                |            |     |     |
| COUT   | <= CAR(4);   |               |                |            |     |     |
end FOR_GENERATE;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 138 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial  |                | : Usage   |          |       |         |            |                |          |         |     |
| -------------- | -------------- | --------- | -------- | ----- | ------- | ---------- | -------------- | -------- | ------- | --- |
| Example        |                | : Another |          | usage |         | of         | for-generation |          | scheme. |     |
| CAR(0)         | <=             | CIN;      |          |       |         |            |                |          |         |     |
| G2 :           | for            | M in      | 3 downto |       | 0       | generate   |                |          |         |     |
| SUM(M)         |                | <= A(M)   |          | xor   | B(M)    | xor        | CAR(M);        |          |         |     |
| CAR(M+1)       |                | <=        | A(M)     | and   | B(M)    | and        | CAR(M);        |          |         |     |
| end generate   |                | G2;       |          |       |         |            |                |          |         |     |
| COUT           | <= CAR(4);     |           |          |       |         |            |                |          |         |     |
| Syntax         | (if-generation |           |          |       | scheme) |            | :              |          |         |     |
| generate-label |                |           |          | : if  |         | expression |                | generate |         |     |
[block-declarations
begin]
concurrent-statements
| end | generate |     | [generate-label]; |     |     |     |     |     |     |     |
| --- | -------- | --- | ----------------- | --- | --- | --- | --- | --- | --- | --- |
The if-generate statement allows a conditional selection of concurrent state-
| ments            | at     | elaboration |     |     | time. |     |           |     |       |     |
| ---------------- | ------ | ----------- | --- | --- | ----- | --- | --------- | --- | ----- | --- |
| (cid:13)c CEERI, | Pilani |             |     |     |       |     | IC Design |     | Group | 139 |

| VHDL | Tutorial |     | : Usage |     |     |     |     |     |     |     |     |     |
| ---- | -------- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Example : A 4-bit counter using both for- and if-generation schemes.
| entity |             | COUNTER4 |        |     | is           |     |         |     |      |     |     |     |
| ------ | ----------- | -------- | ------ | --- | ------------ | --- | ------- | --- | ---- | --- | --- | --- |
|        | port(COUNT, |          |        |     | CLOCK        | :   | in BIT; |     |      |     |     |     |
|        | Q           | :        | buffer |     | BIT_vector(0 |     |         | to  | 3)); |     |     |     |
end COUNTER4;
| architecture |         |     |             | IF_GENERATE |      |      | of  | COUNTER4 |       | is  |     |     |
| ------------ | ------- | --- | ----------- | ----------- | ---- | ---- | --- | -------- | ----- | --- | --- | --- |
| component    |         |     | D_FLIP_FLOP |             |      |      |     |          |       |     |     |     |
|              | port(D, |     | CLK         |             | : in | BIT; | Q   | : out    | BIT); |     |     |     |
end component;
begin
|     | GK    | : for    |          | K in        | 0          | to 3       | generate |     |        |     |     |     |
| --- | ----- | -------- | -------- | ----------- | ---------- | ---------- | -------- | --- | ------ | --- | --- | --- |
|     | GK0   |          | : if     | K           | = 0        | generate   |          |     |        |     |     |     |
|     |       | DFF      | :        | D_FLIP_FLOP |            |            |          |     |        |     |     |     |
|     |       |          | port     |             | map(COUNT, |            | CLOCK,   |     | Q(K)); |     |     |     |
|     | end   |          | generate |             | GK0;       |            |          |     |        |     |     |     |
|     | GK1_3 |          | :        | if          | K >        | 0 generate |          |     |        |     |     |     |
|     |       | DFF      | :        | D_FLIP_FLOP |            |            |          |     |        |     |     |     |
|     |       |          | port     | map(Q(K-1), |            |            | CLOCK,   |     | Q(K)); |     |     |     |
|     | end   |          | generate |             | GK1_3;     |            |          |     |        |     |     |     |
|     | end   | generate |          |             | GK;        |            |          |     |        |     |     |     |
end IF_GENERATE;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     |     |     | IC  | Design | Group | 140 |
| ---------------- | --- | ------ | --- | --- | --- | --- | --- | --- | --- | ------ | ----- | --- |

| VHDL Tutorial | : Usage |     |         |            |           |     |
| ------------- | ------- | --- | ------- | ---------- | --------- | --- |
|               |         |     | Binding | Component  | Instances |     |
|               |         |     | in      | a Generate | Statement |     |
Component instances in a generate statement can be bound to entities using a
block con(cid:2)guration. A block con(cid:2)guration is de(cid:2)ned for each range of generate
labels.
| configuration |     | GENERATE_BIND |     | of FULL_ADD | is  |     |
| ------------- | --- | ------------- | --- | ----------- | --- | --- |
use work.all;
| -- Example       | of  | a declaration |     | in the |     |     |
| ---------------- | --- | ------------- | --- | ------ | --- | --- |
| -- configuration |     | declarative   |     | part.  |     |     |
for FOR_GENERATE
| -- A block       | configuration     |            |                 |           |       |     |
| ---------------- | ----------------- | ---------- | --------------- | --------- | ----- | --- |
| for              | GK(1)             | -- A block | configuration   |           |       |     |
| for              | FA :              | FULL_ADDER |                 |           |       |     |
|                  | use configuration |            | WORK.FA_HA_CON; |           |       |     |
| end              | for;              |            |                 |           |       |     |
| end              | for;              |            |                 |           |       |     |
| (cid:13)c CEERI, | Pilani            |            |                 | IC Design | Group | 141 |

| VHDL    | Tutorial : Usage |                   |              |     |     |     |
| ------- | ---------------- | ----------------- | ------------ | --- | --- | --- |
| for     | GK(2 to          | 3)                |              |     |     |     |
|         | for FA :         | FULL_ADDER        |              |     |     |     |
| -- No   | explicit         | binding.          | Use defaults |     |     |     |
| -- i.e. | use              | entity FULL_ADDER |              |     |     |     |
| -- in   | working          | library.          |              |     |     |     |
|         | end for;         |                   |              |     |     |     |
| end     | for;             |                   |              |     |     |     |
| for     | GK(0)            |                   |              |     |     |     |
|         | for FA :         | FULL_ADDER        |              |     |     |     |
use entity
work.FULL_ADDER(FA_DATAFLOW);
|     | end for; |     |     |     |     |     |
| --- | -------- | --- | --- | --- | --- | --- |
| end | for;     |     |     |     |     |     |
end for;
end GENERATE_BIND;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 142 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Usage |     |     |     |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
Alias Declaration
| Syntax | :          |     |     |                  |     |     |     |     |     |
| ------ | ---------- | --- | --- | ---------------- | --- | --- | --- | --- | --- |
| alias  | identifier |     | [:  | identifier-type] |     |     |     |     |     |
is item-name;
A named item can be an object i.e. a constant, signal, variable or (cid:2)le.
| Example          | :         |                |              |                 |           |        |       |     |     |
| ---------------- | --------- | -------------- | ------------ | --------------- | --------- | ------ | ----- | --- | --- |
| variable         | DATA_WORD |                |              | : BIT_vector(15 |           | downto |       | 0); |     |
| alias            | DATA_BUS  | :              | BIT_vector(7 |                 | downto    |        | 0) is |     |     |
|                  |           |                |              | DATA_WORD(15    |           | downto | 8);   |     |     |
| alias            | STATUS    | : BIT_vector(0 |              |                 | to 3)     | is     |       |     |     |
| (cid:13)c CEERI, | Pilani    |                |              |                 | IC Design | Group  |       |     | 143 |

| VHDL Tutorial | :        | Usage         |        |                  |     |         |          |              |        |
| ------------- | -------- | ------------- | ------ | ---------------- | --- | ------- | -------- | ------------ | ------ |
|               |          |               |        | DATA_WORD(3      |     | downto  | 0);      |              |        |
| alias         | RESET    | :             | BIT is | DATA_WORD(4);    |     |         |          |              |        |
| alias         | RX_READY |               | : BIT  | is DATA_WORD(5); |     |         |          |              |        |
|               |          |               |        | DATA             | BUS |         |          | DATA WORD(15 | downto |
| Given         | these    | declarations, |        |                  | can | be used | wherever |              |        |
8) is needed; RESET can be used wherever DATA WORD(4) is needed and so
on.
Assigning value to an alias name is the same thing as assigning value to the
| aliased          | name.  |     |     |     |           |       |     |     |     |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- | --- | --- |
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group |     |     | 144 |

| VHDL | Tutorial : Usage |     |            |     |              |     |
| ---- | ---------------- | --- | ---------- | --- | ------------ | --- |
|      |                  |     | File Types | and | File Objects |     |
Objects of (cid:2)le types represent (cid:2)les in the host environment. They provide
a mechanism by which a VHDL design communicates with the host computer
environment.
| Syntax           | (of a          | (cid:2)le type | is) :          |               |       |     |
| ---------------- | -------------- | -------------- | -------------- | ------------- | ----- | --- |
| type             | file-type-name |                | is file        | of type-name; |       |     |
| Example          | :              |                |                |               |       |     |
| type             | VECTORS        | is file        | of BIT_vector; |               |       |     |
| type             | NAMES          | is file        | of STRING;     |               |       |     |
| (cid:13)c CEERI, | Pilani         |                |                | IC Design     | Group | 145 |

| VHDL Tutorial | : Usage |     |     |     |     |     |     |
| ------------- | ------- | --- | --- | --- | --- | --- | --- |
A (cid:2)le of type VECTORS has a sequence of values of type BIT vector; a (cid:2)le of
NAMES
| type        | has                | a sequence |       | of strings               | as values | in it. |     |
| ----------- | ------------------ | ---------- | ----- | ------------------------ | --------- | ------ | --- |
| A (cid:2)le | object is declared |            | using | a (cid:2)le declaration. |           |        |     |
Note that these (cid:2)les are binary (cid:2)les. For text (cid:2)les, use TEXTIO package.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     | 146 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- |

| VHDL   | Tutorial : Usage |                  |       |     |     |     |
| ------ | ---------------- | ---------------- | ----- | --- | --- | --- |
| Syntax | (of a            | (cid:2)le object | is) : |     |     |     |
| file   | file-name        | : file-type-name |       |     | is  |     |
mode string-expression;
| Example | :        |           |     |     |     |     |
| ------- | -------- | --------- | --- | --- | --- | --- |
| file    | VEC_FILE | : VECTORS |     | is  |     |     |
in "/home/rs/asp/div.vec";
| file | OUTPUT | : NAMES | is  | out "stdout"; |     |     |
| ---- | ------ | ------- | --- | ------------- | --- | --- |
VEC FILE is declared to be a (cid:2)le that contains a sequence of BIT vectors and
"/home/rs/asp/div.vec"
it is an input (cid:2)le. It is associated with the (cid:2)le in the
| host | environment. |     |     |     |     |     |
| ---- | ------------ | --- | --- | --- | --- | --- |
Procedures and functions that are implicitly declared for each (cid:2)le type are :
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 147 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL             | Tutorial | : Usage   |               |       |            |                    |             |             |          |        |       |     |
| ---------------- | -------- | --------- | ------------- | ----- | ---------- | ------------------ | ----------- | ----------- | -------- | ------ | ----- | --- |
| procedure        |          | READ(F    |               | :     | in         | file-type-name;    |             |             |          |        |       |     |
|                  |          |           |               | VALUE |            | : out              | type-name); |             |          |        |       |     |
| -- Gets          |          | the       | next          | value |            | in                 | VALUE       |             | from     | file   | F.    |     |
| procedure        |          | WRITE(F   |               |       | : out      | file-type-name;    |             |             |          |        |       |     |
|                  |          |           |               |       | VALUE      | :                  | in          | type-name); |          |        |       |     |
| -- Appends       |          | a         | given         |       | value      |                    | in          | VALUE       | to       | file   | F.    |     |
| function         |          | ENDFILE(F |               |       | :          | in file-type-name) |             |             |          |        |       |     |
|                  |          |           |               |       |            |                    | return      |             | BOOLEAN; |        |       |     |
| -- Returns       |          | FALSE     |               | if    | a          | read               |             | on          | an input |        |       |     |
| -- file          |          | F will    |               | be    | successful |                    |             | in          | getting  |        |       |     |
| -- another       |          | value,    |               |       | otherwise  |                    |             | it          | returns  |        | TRUE. |     |
| procedure        |          | READ      |               | (F    | : in       | file-type-name;    |             |             |          |        |       |     |
| VALUE            |          | : out     | type-name;    |       |            |                    |             |             |          |        |       |     |
|                  |          | LENGTH    |               | :     | out        | NATURAL);          |             |             |          |        |       |     |
| -- LENGTH        |          | returns   |               |       | the        | number             |             | of          | elements |        |       |     |
| -- of            | the      | array     |               | that  |            | was                | read.       |             | A file   |        |       |     |
| -- cannot        |          | be        | opened        |       | or         | closed             |             | explicitly, |          |        |       |     |
| -- and           |          | values    | within        |       |            | a file             |             | can         | only     | be     |       |     |
| -- accessed      |          |           | sequentially. |       |            |                    |             |             |          |        |       |     |
| (cid:13)c CEERI, |          | Pilani    |               |       |            |                    |             |             | IC       | Design | Group | 148 |

| VHDL             | Tutorial  |             | : Usage |            |                          |                          |              |             |     |           |       |     |
| ---------------- | --------- | ----------- | ------- | ---------- | ------------------------ | ------------------------ | ------------ | ----------- | --- | --------- | ----- | --- |
| Example          |           |             | :       | Usage      |                          | of                       | (cid:2)les.  |             |     |           |       |     |
| entity           |           | FA_TEST     |         |            | is                       | end                      | FA_TEST;     |             |     |           |       |     |
| architecture     |           |             |         | IO_EXAMPLE |                          |                          |              | of FA_TEST  |     | is        |       |     |
|                  | component |             |         | FULL_ADD   |                          |                          |              |             |     |           |       |     |
|                  | port(CIN, |             |         |            | A,                       | B :                      | in           | BIT;        |     |           |       |     |
|                  |           |             | COUT,   |            | SUM                      | :                        | out          | BIT);       |     |           |       |     |
|                  | end       | component;  |         |            |                          |                          |              |             |     |           |       |     |
|                  | subtype   |             | STRING3 |            |                          | is                       | BIT_vector(0 |             |     | to 2);    |       |     |
|                  | subtype   |             | STRING2 |            |                          | is                       | BIT_vector(0 |             |     | to 1);    |       |     |
|                  | type      | IN_TYPE     |         |            | is                       | file                     | of           | STRING3;    |     |           |       |     |
|                  | type      | OUT_TYPE    |         |            | is                       | file                     |              | of STRING2; |     |           |       |     |
|                  | file      | VEC_FILE    |         |            | :                        | IN_TYPE                  |              | is          |     |           |       |     |
|                  |           |             |         | in         | "/home/rs/asp/fadd.vec"; |                          |              |             |     |           |       |     |
|                  | file      | RESULT_FILE |         |            |                          | :                        | OUT_TYPE     |             | is  |           |       |     |
|                  |           |             |         | out        |                          | "/home/rs/asp/fadd.out"; |              |             |     |           |       |     |
|                  | signal    |             | S       | : STRING3; |                          |                          |              |             |     |           |       |     |
|                  | signal    |             | Q       | : STRING2; |                          |                          |              |             |     |           |       |     |
| (cid:13)c CEERI, |           | Pilani      |         |            |                          |                          |              |             |     | IC Design | Group | 149 |

| VHDL | Tutorial : Usage |     |     |     |     |     |     |
| ---- | ---------------- | --- | --- | --- | --- | --- | --- |
begin
|     | FA : FULL_ADD | port | map(S(0), |       | S(1),  |     |     |
| --- | ------------- | ---- | --------- | ----- | ------ | --- | --- |
|     |               |      | S(2),     | Q(0), | Q(1)); |     |     |
process
|     | constant | PROPAGATION_DELAY |            |          | :      |     |     |
| --- | -------- | ----------------- | ---------- | -------- | ------ | --- | --- |
|     |          |                   |            | TIME :=  | 25 ns; |     |     |
|     | variable | IN_STR            | : STRING3; |          |        |     |     |
|     | variable | OUT_STR           | :          | STRING2; |        |     |     |
begin
|                  | while(not          | ENDFILE(VEC_FILE))     |          |           | loop      |       |     |
| ---------------- | ------------------ | ---------------------- | -------- | --------- | --------- | ----- | --- |
|                  | READ(VEC_FILE,     |                        | IN_STR); |           |           |       |     |
|                  | S <=               | IN_STR;                |          |           |           |       |     |
|                  | wait               | for PROPOGATION_DELAY; |          |           |           |       |     |
|                  | OUT_STR            | :=                     | Q;       |           |           |       |     |
|                  | WRITE(RESULT_FILE, |                        |          | OUT_STR); |           |       |     |
| (cid:13)c CEERI, | Pilani             |                        |          |           | IC Design | Group | 150 |

| VHDL Tutorial | : Usage      |     |     |     |
| ------------- | ------------ | --- | --- | --- |
| end           | loop;        |     |     |     |
| assert        | FALSE        |     |     |     |
| report        | "Completed"; |     |     |     |
| end           | process;     |     |     |     |
end IO_EXAMPLE;
| (cid:13)c CEERI, | Pilani | IC Design | Group | 151 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Usage |     |     |           |       |     |
| ------------- | ------- | --- | --- | --------- | ----- | --- |
|               |         |     |     | Text File | Usage |     |
TEXTIO
The pre-de(cid:2)ned package (given in Annexure-II) contains procedures
and functions that provide a means for reading and writing text (cid:2)les. Thus, text
(cid:2)les containing vectors (perhaps generated manually or by another program)
| can be | used to | drive simulations. |     |     |     |     |
| ------ | ------- | ------------------ | --- | --- | --- | --- |
Similarly, the simulation outputs being monitored can be written onto text (cid:2)les
| for manual | examination |     | or use | by another | tool. |     |
| ---------- | ----------- | --- | ------ | ---------- | ----- | --- |
Examples:
| use STD.TEXTIO.all; |     |     |     |     |     |     |
| ------------------- | --- | --- | --- | --- | --- | --- |
This clause makes all the procedures and functions for text input/output con-
tained in package TEXTIO analysed in library STD visible in the following design
unit.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 152 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial | : Usage |        |     |     |                     |     |     |
| ---- | -------- | ------- | ------ | --- | --- | ------------------- | --- | --- |
| file | VECTORS  |         | : TEXT | is  | in  | "/home/rs/vec.txt"; |     |     |
Open (cid:2)le "/home/rs/vec.txt" as (cid:2)le object named VECTORS of (cid:2)le type TEXT
| in input |     | mode. |     |     |     |     |     |     |
| -------- | --- | ----- | --- | --- | --- | --- | --- | --- |
TEXT TEXTIO
Type is a pre-declared type in package whose declaration is as
| follows | :    |     |      |            |     |     |     |     |
| ------- | ---- | --- | ---- | ---------- | --- | --- | --- | --- |
| type    | TEXT | is  | file | of STRING; |     |     |     |     |
The process in which the (cid:2)le is read may look as follows :
process(CLOCK)
| variable         |        | BUF             | : LINE;     |         |     |            |       |     |
| ---------------- | ------ | --------------- | ----------- | ------- | --- | ---------- | ----- | --- |
| -- LINE          |        | is pre-declared |             | type    | in  | package    |       |     |
| -- TEXTIO        |        | whose           | declaration |         | is  | as follows | :     |     |
| -- type          |        | LINE is         | access      | STRING; |     |            |       |     |
| (cid:13)c CEERI, | Pilani |                 |             |         |     | IC Design  | Group | 153 |

| VHDL         | Tutorial | : Usage |        |      |                |     |        |     |         |     |     |     |
| ------------ | -------- | ------- | ------ | ---- | -------------- | --- | ------ | --- | ------- | --- | --- | --- |
| -- Thus,     |          | type    |        | LINE | is             | an  | access |     | type    |     |     |     |
| -- (pointer) |          |         | which  |      | points         |     | to     | a   | STRING. |     |     |     |
| variable     |          |         | N1_VAR |      | : BIT_vector(0 |     |        |     | to      | 3); |     |     |
| variable     |          |         | N2_VAR |      | : integer;     |     |        |     |         |     |     |     |
begin
| if               | ((CLOCK’event     |            |                   |            | and  | CLOCK |           | =       | ’1’) | and    |       |     |
| ---------------- | ----------------- | ---------- | ----------------- | ---------- | ---- | ----- | --------- | ------- | ---- | ------ | ----- | --- |
|                  | (not              |            | ENDFILE(VECTORS)) |            |      |       |           | then    |      |        |       |     |
|                  | READLINE(VECTORS, |            |                   |            |      | BUF); |           |         |      |        |       |     |
| -- READ()        |                   | is         | an                | overloaded |      |       | procedure |         |      |        |       |     |
|                  | READ(BUF,         |            |                   | N1_VAR);   |      |       |           |         |      |        |       |     |
|                  | READ(BUF,         |            |                   | N2_VAR);   |      |       |           |         |      |        |       |     |
| -- apply         |                   | values     |                   | read       | to   | input |           | signals |      |        |       |     |
| -- of            | entity            |            | under             |            | test |       |           |         |      |        |       |     |
|                  | N1                | <= N1_VAR; |                   |            |      |       |           |         |      |        |       |     |
| (cid:13)c CEERI, |                   | Pilani     |                   |            |      |       |           |         | IC   | Design | Group | 154 |

| VHDL Tutorial | : Usage            |     |               |     |     |     |
| ------------- | ------------------ | --- | ------------- | --- | --- | --- |
| N2            | <= N2_VAR;         |     |               |     |     |     |
| elsif         | (ENDFILE(VECTORS)) |     | then          |     |     |     |
| report        | "Finished          | All | the Vectors"; |     |     |     |
| end           | if;                |     |               |     |     |     |
end process;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 155 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Usage |            |     |     |
| ------------- | ------- | ---------- | --- | --- |
|               |         | Test Bench |     |     |
To test the VHDL model of any digital hardware we need to apply test stimuli
waveforms to its inputs, capture the response waveforms at the model’s out-
puts and compare the captured response waveforms with the expected output
waveforms.
VHDL
A model written for the above purpose essentially simulates the running
of a test on a hardware test setup with the Device Under Test (DUT) plugged
in the DUT socket (cid:151) and is typically called a test bench.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 156 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Usage |     |     |     |
| ------------- | ------- | --- | --- | --- |
(cid:11) (cid:8)
|     | Test | Bench | Blocks |     |
| --- | ---- | ----- | ------ | --- |
(cid:10) (cid:9)
STIMULUS DEVICE
RESPONSE   CAPTURE
UNDER
GENERATOR AND    COMPARISON
TEST
One can use VHDL not only for modeling the device (DUT) but also for modeling
the Stimulus Generator, Response Capture and Response Analysis Block i.e.
| the entire       | test bench. |           |       |     |
| ---------------- | ----------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani      | IC Design | Group | 157 |

| VHDL    | Tutorial   | : Usage   |      |       |     |           |     |     |     |     |     |     |
| ------- | ---------- | --------- | ---- | ----- | --- | --------- | --- | --- | --- | --- | --- | --- |
| Example | :          | A typical | test | bench |     | template. |     |     |     |     |     |     |
| entity  | TEST_BENCH |           | is   |       |     |           |     |     |     |     |     |     |
end TEST_BENCH;
| architecture |     | ILLUSTRATIVE |      |           |     | of  | TEST_BENCH   |     |     | is  |     |     |
| ------------ | --- | ------------ | ---- | --------- | --- | --- | ------------ | --- | --- | --- | --- | --- |
| -- declare   |     | DUT          | in a | component |     |     | declaration. |     |     |     |     |     |
-- declare local signals that will connect to the DUT’s I/O’s.
begin
| -- Include  |        | a process |           | that  |         | will    |     | generate    |          | the     |       |     |
| ----------- | ------ | --------- | --------- | ----- | ------- | ------- | --- | ----------- | -------- | ------- | ----- | --- |
| -- stimulus |        | waveforms |           |       | on      | signals |     | that        |          | will    |       |     |
| -- connect  |        | to        | the DUT’s |       | inputs. |         |     | Instantiate |          |         |       |     |
| -- the      | DUT    | such      | that      | these |         | signals |     |             | connects |         |       |     |
| -- to       | the    | DUT’s     | inputs.   |       | Include |         |     | a process   |          |         |       |     |
| -- that     | will   | monitor   |           | and   |         | compare |     | the         | captured |         |       |     |
| -- response |        | waveforms |           |       | from    | the     |     | DUT’s       | outputs  |         |       |     |
| -- by       | having | all       | the       | local |         | signals |     |             | that     | connect |       |     |
| -- to       | the    | DUT’s     | outputs   |       | on      | its     |     | sensitivity |          |         | list. |     |
end ILLUSTRATIVE;
| (cid:13)c CEERI, | Pilani |     |     |     |     |     |     | IC  | Design | Group |     | 158 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | --- | ------ | ----- | --- | --- |

VHDL Tutorial : Examples
Introduction
1.
Overview
2.
Constructs
3.
Usage
4.
Examples
5.
(cid:13)c CEERI, Pilani IC Design Group 159

| VHDL Tutorial | : Examples |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- |
Behavioural Modeling
Modeling hardware as a single functional block with an interface to the external
world (de(cid:2)ned through an entity declaration) and its functionality and timing
behaviour being described in the architecture body using one or more process
statements.
| Where | do we | need behavioural | modeling | ?   |     |
| ----- | ----- | ---------------- | -------- | --- | --- |
In the top-down design approach which is used for designing complex chip-
s/systems.
In this approach, as a (cid:2)rst step we focus on capturing the functional and timing
behaviour (speci(cid:2)cations) of the chip correctly (cid:151) without worrying about how
to realize them. Thus, we build a behavioural model of the chip/system and
| validate         | it.    |     |           |       |     |
| ---------------- | ------ | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 160 |

| VHDL Tutorial | : Examples |     |     |     |
| ------------- | ---------- | --- | --- | --- |
We also need behavioural models for cells in a cell library (standard cell library
| or gate          | array library). |           |       |     |
| ---------------- | --------------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani          | IC Design | Group | 161 |

| VHDL Tutorial | : Examples |             |          |             |                |             |      |     |
| ------------- | ---------- | ----------- | -------- | ----------- | -------------- | ----------- | ---- | --- |
|               |            |             | (cid:11) |             |                | (cid:8)     |      |     |
|               |            |             |          | Behavioural | Modeling       |             |      |     |
|               |            |             | (cid:10) |             |                | (cid:9)     |      |     |
|               |            | Requirement |          |             | VHDL           | Construct   |      |     |
|               |            | Interface   | of the   | chip        | ! entity       | declaration |      |     |
|               |            | Behaviour   | of the   | chip        | ! architecture |             | body |     |
!
|     |     | Input   | pins whose |     | sensitivity  | list | of         |     |
| --- | --- | ------- | ---------- | --- | ------------ | ---- | ---------- | --- |
|     |     | changes | stimulate  |     | the process  |      | statement  |     |
|     |     | Output  | changes    |     | or use       | wait | statement  |     |
|     |     | Details | of the     |     | ! sequential |      | statements |     |
process
|     |     | behaviour | : functional |     | included | in  |     |     |
| --- | --- | --------- | ------------ | --- | -------- | --- | --- | --- |
and timing statement
| (cid:13)c CEERI, | Pilani |     |     | IC  | Design Group |     |     | 162 |
| ---------------- | ------ | --- | --- | --- | ------------ | --- | --- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
I1
AND
I2
Z
OR
I3
| Example  | : Behavioural | modeling  | of AOI | circuit.  |     |     |
| -------- | ------------- | --------- | ------ | --------- | --- | --- |
| entity   | AOI is        |           |        |           |     |     |
| port(I1, | I2, I3        | : in BIT; | Z :    | out BIT); |     |     |
end AOI;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 163 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL         | Tutorial | :   | Examples   |     |        |     |     |     |
| ------------ | -------- | --- | ---------- | --- | ------ | --- | --- | --- |
| architecture |          |     | BEHAVIOUR1 |     | of AOI | is  |     |     |
begin
|     | process(I1, |     |     | I2, I3) |           |     |     |     |
| --- | ----------- | --- | --- | ------- | --------- | --- | --- | --- |
|     | variable    |     | V1, | V2,     | V3 : BIT; |     |     |     |
begin
|     | V1  | :=       | I1 and | I2; |     |     |     |     |
| --- | --- | -------- | ------ | --- | --- | --- | --- | --- |
|     | V2  | :=       | V1 or  | I3; |     |     |     |     |
|     | V3  | :=       | not    | V2; |     |     |     |     |
|     | Z   | <= V3    | after  | 3   | ns; |     |     |     |
|     | end | process; |        |     |     |     |     |     |
end BEHAVIOUR1;
| (cid:13)c CEERI, |     | Pilani |     |     |     | IC Design | Group | 164 |
| ---------------- | --- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
In the top-down design method after initially capturing the behavioural descrip-
tion, such as the one in the example above (comprising of a single process
statement), partitioning of the behaviour into multiple interacting processes is
done.
In the next step, entities can be de(cid:2)ned that have their behaviours described
by the individual processes. These entities can then be connected (via cor-
responding component declarations, their instantiations and con(cid:2)gurations) to
| produce | a structural | description. |     |     |     |     |
| ------- | ------------ | ------------ | --- | --- | --- | --- |
This constitutes one step downwards in the top-down design procedure. More
than one downward steps are typically required before the components be-
| come             | realizable/ | synthesisable | through   | a bottom-up | step. |     |
| ---------------- | ----------- | ------------- | --------- | ----------- | ----- | --- |
| (cid:13)c CEERI, | Pilani      |               | IC Design | Group       |       | 165 |

| VHDL   | Tutorial |     | : Examples |         |      |     |           |     |     |
| ------ | -------- | --- | ---------- | ------- | ---- | --- | --------- | --- | --- |
| entity |          | AOI | is         |         |      |     |           |     |     |
|        | port(I1, |     | I2,        | I3 : in | BIT; | Z : | out BIT); |     |     |
end AOI;
| architecture |        |     | BEHAVIOUR2 |     | of  | AOI | is  |     |     |
| ------------ | ------ | --- | ---------- | --- | --- | --- | --- | --- | --- |
|              | signal |     | S1 : BIT;  |     |     |     |     |     |     |
begin
|     | P1 : | process(I1, |     | I2) |     |     |     |     |     |
| --- | ---- | ----------- | --- | --- | --- | --- | --- | --- | --- |
begin
|     | S1   | <=          | I1 and | I2 after |     | 1 ns; |     |     |     |
| --- | ---- | ----------- | ------ | -------- | --- | ----- | --- | --- | --- |
|     | end  | process     | P1;    |          |     |       |     |     |     |
|     | P2 : | process(S1, |        | I3)      |     |       |     |     |     |
begin
|     | Z   | <=      | S1 nor | I3 after | 2   | ns; |     |     |     |
| --- | --- | ------- | ------ | -------- | --- | --- | --- | --- | --- |
|     | end | process | P2;    |          |     |     |     |     |     |
end BEHAVIOUR2;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     | IC Design | Group | 166 |
| ---------------- | --- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL     | Tutorial | : Examples |     |      |      |           |       |       |              |     |
| -------- | -------- | ---------- | --- | ---- | ---- | --------- | ----- | ----- | ------------ | --- |
|          |          |            |     |      |      | Behaviour |       |       | to Structure |     |
| entity   | AOI      | is         |     |      |      |           |       |       |              |     |
| port(I1, |          | I2,        | I3  | : in | BIT; | Z         | : out | BIT); |              |     |
end AOI;
| architecture |     | STRUCT1 |      | of   | AOI | is    |       |     |     |     |
| ------------ | --- | ------- | ---- | ---- | --- | ----- | ----- | --- | --- | --- |
| signal       |     | S1 :    | BIT; |      |     |       |       |     |     |     |
| component    |     | P1      |      |      |     |       |       |     |     |     |
| port(I1,     |     | I2      | : in | BIT; | Z   | : out | BIT); |     |     |     |
end component;
| -- note          | that      | we       | require |         | only | one | kind |        |       |     |
| ---------------- | --------- | -------- | ------- | ------- | ---- | --- | ---- | ------ | ----- | --- |
| -- of            | component |          | here    | as      | both | AND | and  |        |       |     |
| -- NOR           | gates     | are      | of      | 2-input |      | and |      |        |       |     |
| -- 1-output      |           | variety. |         |         |      |     |      |        |       |     |
| (cid:13)c CEERI, | Pilani    |          |         |         |      |     | IC   | Design | Group | 167 |

| VHDL Tutorial    |     | : Examples          |                 |         |              |         |     |     |
| ---------------- | --- | ------------------- | --------------- | ------- | ------------ | ------- | --- | --- |
| -- configuration |     |                     | specifications. |         |              |         |     |     |
| -- assuming      |     | entity-architecture |                 |         |              | pair is |     |     |
| -- defined       |     | for                 | AND2            | and     | NOR2         | gates.  |     |     |
| for U1           | :   | P1 use              | entity          |         | AND2(AND2)   |         |     |     |
|                  |     |                     | port            | map(I1, |              | I2, Z); |     |     |
| -- (AND2)        |     | specifies           |                 | the     | architecture |         |     |     |
| -- chosen        |     | for                 | the             | entity  | AND2.        |         |     |     |
| for U2           | :   | P1 use              | entity          |         | NOR2(NOR2)   |         |     |     |
|                  |     |                     | port            | map(I1, |              | I2, Z); |     |     |
| -- (NOR2)        |     | specifies           |                 | the     | architecture |         |     |     |
| -- chosen        |     | for                 | the             | entity  | NOR2.        |         |     |     |
begin
| U1  | : P1 | port | map(I1, |     | I2, | S1); |     |     |
| --- | ---- | ---- | ------- | --- | --- | ---- | --- | --- |
| U2  | : P1 | port | map(S1, |     | I3, | Z);  |     |     |
end STRUCT1;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group | 168 |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |            |     |          |     |     |     |
| ------------- | ---------- | --- | ---------- | --- | -------- | --- | --- | --- |
|               |            |     | Structural |     | Modeling |     |     |     |
Modeling of the chip/system as an interconnection of available cells, parts,
| and/or | components. |                             |             |     |               |             |     |     |
| ------ | ----------- | --------------------------- | ----------- | --- | ------------- | ----------- | --- | --- |
|        |             | Requirement                 |             |     | VHDL          | Construct   |     |     |
|        |             | Description                 | of external |     | ! entity      | declaration |     |     |
|        |             | interface of                | the chip    |     |               |             |     |     |
|        |             | Description                 | of list     | of  | ! component   | declaration |     |     |
|        |             | component/part              | types       |     |               |             |     |     |
|        |             | (with pin identi(cid:2)ers) |             |     |               |             |     |     |
|        |             | Description                 | of actual   |     | ! component   |             |     |     |
|        |             | placements                  |             |     | instantiation |             |     |     |
|        |             | (instantiations)            | of          |     | statements    |             |     |     |
port map)
|     |     | components  | and          | wiring | (with     |                     |     |     |
| --- | --- | ----------- | ------------ | ------ | --------- | ------------------- | --- | --- |
|     |     | Description | of the       |        | ! Implied | (cid:3) or Explicit | y   |     |
|     |     | behaviour   | of instanced |        |           |                     |     |     |
parts/components
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group |     |     | 169 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- | --- | --- |

| VHDL Tutorial | : Examples |     |     |     |
| ------------- | ---------- | --- | --- | --- |
(cid:3)
Implied : An entity of the same name as the component together with its
associated most recently analyzed architecture supplies the behaviour for the
| instanced | part. |     |     |     |
| --------- | ----- | --- | --- | --- |
y
Explicit : The con(cid:2)guration speci(cid:2)cation or the con(cid:2)guration declaration
serve to bind a particular instance or a chosen set of instances to speci(cid:2)c
entity-architecture pairs that would supply the behaviour for the instance.
| (cid:13)c CEERI, | Pilani | IC Design | Group | 170 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
Example 1 : Bottom-up Design using one’s own cells and implicit con(cid:2)guration.
VHDL
In the design (cid:2)le, incorporate models (entity-architecture pairs) for all the
| cells | to be used. |     |     |     |     |     |
| ----- | ----------- | --- | --- | --- | --- | --- |
Write the entity declaration for the hardware model under development using
| the bottom-up |     | design | approach. |     |     |     |
| ------------- | --- | ------ | --------- | --- | --- | --- |
In the (structural) architecture body, declare components with the same names
and port speci(cid:2)cations as the entity names for each of the cells.
Build the structural architecture for the design by instantiating these compo-
nents. Default bindings for component instances to entity-architecture pairs
are used in this case (by default, an instance of a component binds to the
most recently analyzed architecture of the visible entity of the same name and
| port speci(cid:2)cations |        | as  | the component, |           | if present). |     |
| ------------------------ | ------ | --- | -------------- | --------- | ------------ | --- |
| (cid:13)c CEERI,         | Pilani |     |                | IC Design | Group        | 171 |

| VHDL Tutorial |      | : Examples |     |      |         |       |     |     |     |
| ------------- | ---- | ---------- | --- | ---- | ------- | ----- | --- | --- | --- |
| entity        | AND2 | is         |     |      |         |       |     |     |     |
| port(I1,      |      | I2 :       | in  | BIT; | Z : out | BIT); |     |     |     |
end AND2;
| architecture |     | AND2 | of  | AND2 | is  |     |     |     |     |
| ------------ | --- | ---- | --- | ---- | --- | --- | --- | --- | --- |
begin
| Z <= | I1  | and I2 | after | 1   | ns; |     |     |     |     |
| ---- | --- | ------ | ----- | --- | --- | --- | --- | --- | --- |
end AND2;
| entity   | NOR2 | is   |     |      |         |       |     |     |     |
| -------- | ---- | ---- | --- | ---- | ------- | ----- | --- | --- | --- |
| port(I1, |      | I2 : | in  | BIT; | Z : out | BIT); |     |     |     |
end NOR2;
| architecture |     | NOR2 | of  | NOR2 | is  |     |     |     |     |
| ------------ | --- | ---- | --- | ---- | --- | --- | --- | --- | --- |
begin
| Z <= | I1  | nor I2 | after | 1   | ns; |     |     |     |     |
| ---- | --- | ------ | ----- | --- | --- | --- | --- | --- | --- |
end NOR2;
-----------------------------------------
| entity   | AOI | is  |      |         |     |       |       |     |     |
| -------- | --- | --- | ---- | ------- | --- | ----- | ----- | --- | --- |
| port(I1, |     | I2, | I3 : | in BIT; | Z   | : out | BIT); |     |     |
end AOI;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC  | Design | Group | 172 |
| ---------------- | ------ | --- | --- | --- | --- | --- | ------ | ----- | --- |

| VHDL         | Tutorial       | : Examples      |      |         |     |        |     |     |
| ------------ | -------------- | --------------- | ---- | ------- | --- | ------ | --- | --- |
| architecture |                | STRUCTURAL_VIEW |      |         | of  | AOI is |     |     |
|              | signal         | S1 : BIT;       |      |         |     |        |     |     |
|              | component      | AND2            |      |         |     |        |     |     |
|              | port(A,        | B : in          | BIT; | C :     | out | BIT);  |     |     |
|              | end component; |                 |      |         |     |        |     |     |
|              | component      | NOR2            |      |         |     |        |     |     |
|              | port(X,        | Y : in          | BIT; | Z :     | out | BIT);  |     |     |
|              | end component; |                 |      |         |     |        |     |     |
| --           | default        | configuration   |      | applies |     |        |     |     |
| --           | in this        | case.           |      |         |     |        |     |     |
begin
|     | U1 : AND2 | port | map(I1, | I2, | S1); |     |     |     |
| --- | --------- | ---- | ------- | --- | ---- | --- | --- | --- |
|     | U2 : NOR2 | port | map(S1, | I3, | Z);  |     |     |     |
end STRUCTURAL_VIEW;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group | 173 |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- |
Example 2 : Use of pre-compiled design libraries for Bottom-up structural de-
| sign description. |     |     |     |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- |
In this case, we assume that the entity declaration and architecture body of
each of the (cid:147)cells(cid:148) has been pre-compiled in a design library, cell lib and
component declarations with same names and port lists as each of the entities
are declared in a package named cell list which has also been compiled in
| the library, | cell lib. |     |     |     |     |     |
| ------------ | --------- | --- | --- | --- | --- | --- |
The design (cid:2)le containing entity-architecture pairs for cells and corresponding
component declarations contained in a package suited for Example 1 is as
follows.
| entity   | AND2 is |      |         |       |     |     |
| -------- | ------- | ---- | ------- | ----- | --- | --- |
| port(I1, | I2 : in | BIT; | Z : out | BIT); |     |     |
end AND2;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 174 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL   | Tutorial |      | : Examples |     |      |         |       |     |     |
| ------ | -------- | ---- | ---------- | --- | ---- | ------- | ----- | --- | --- |
| entity |          | NOR2 | is         |     |      |         |       |     |     |
|        | port(I1, |      | I2 :       | in  | BIT; | Z : out | BIT); |     |     |
end NOR2;
| architecture |     |     | AND2 | of  | AND2 | is  |     |     |     |
| ------------ | --- | --- | ---- | --- | ---- | --- | --- | --- | --- |
begin
|     | Z <= | I1  | and I2 | after | 1   | ns; |     |     |     |
| --- | ---- | --- | ------ | ----- | --- | --- | --- | --- | --- |
end AND2;
| architecture |     |     | NOR2 | of  | NOR2 | is  |     |     |     |
| ------------ | --- | --- | ---- | --- | ---- | --- | --- | --- | --- |
begin
|     | Z <= | I1  | nor I2 | after | 1   | ns; |     |     |     |
| --- | ---- | --- | ------ | ----- | --- | --- | --- | --- | --- |
end NOR2;
| package          |           | cell_list  |      | is  |      |         |           |       |     |
| ---------------- | --------- | ---------- | ---- | --- | ---- | ------- | --------- | ----- | --- |
|                  | component |            | AND2 |     |      |         |           |       |     |
|                  | port(A,   |            | B :  | in  | BIT; | C : out | BIT);     |       |     |
|                  | end       | component; |      |     |      |         |           |       |     |
|                  | component |            | NOR2 |     |      |         |           |       |     |
|                  | port(X,   |            | Y :  | in  | BIT; | Z : out | BIT);     |       |     |
| (cid:13)c CEERI, |           | Pilani     |      |     |      |         | IC Design | Group | 175 |

| VHDL Tutorial | : Examples |     |     |     |
| ------------- | ---------- | --- | --- | --- |
| end           | component; |     |     |     |
end cell_list;
| (cid:13)c CEERI, | Pilani | IC Design | Group | 176 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | :   | Examples |     |     |     |     |     |
| ------------- | --- | -------- | --- | --- | --- | --- | --- |
Now, the hardware model of AOI (using a structural architecture body) can be
| described |           | by the | following | design | (cid:2)le. |     |     |
| --------- | --------- | ------ | --------- | ------ | ---------- | --- | --- |
| library   | cell_lib; |        |           |        |            |     |     |
use cell_lib.cell_list.all;
| entity   | AOI | is  |         |          |           |     |     |
| -------- | --- | --- | ------- | -------- | --------- | --- | --- |
| port(I1, |     | I2, | I3 : in | BIT; Z : | out BIT); |     |     |
end AOI;
| architecture |     | structural_view |     | of  | AOI is |     |     |
| ------------ | --- | --------------- | --- | --- | ------ | --- | --- |
| signal       | S1  | : BIT;          |     |     |        |     |     |
begin
| U1 : | AND2 | port | map(I1, | I2, S1); |     |     |     |
| ---- | ---- | ---- | ------- | -------- | --- | --- | --- |
| U2 : | NOR2 | port | map(S1, | I3, Z);  |     |     |     |
end structural_view;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 177 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |          |                    |     |        |     |     |
| ------------- | ---------- | -------- | ------------------ | --- | ------ | --- | --- |
| Example       | 3 :        | Explicit | con(cid:2)guration |     | usage. |     |     |
It is possible to declare component names that are different from the entity
| names | for the | corresponding |     | cells. |     |     |     |
| ----- | ------- | ------------- | --- | ------ | --- | --- | --- |
A structural description using such component names would require explicit
con(cid:2)guration as default con(cid:2)guration rules would not be able to supply the
con(cid:2)guration.
| entity   | AND2 is |      |      |         |       |     |     |
| -------- | ------- | ---- | ---- | ------- | ----- | --- | --- |
| port(I1, | I2      | : in | BIT; | Z : out | BIT); |     |     |
end AND2;
| entity   | NOR2 is |      |      |         |       |     |     |
| -------- | ------- | ---- | ---- | ------- | ----- | --- | --- |
| port(I1, | I2      | : in | BIT; | Z : out | BIT); |     |     |
end NOR2;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 178 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL         | Tutorial |     | : Examples |         |      |     |     |     |     |     |
| ------------ | -------- | --- | ---------- | ------- | ---- | --- | --- | --- | --- | --- |
| architecture |          |     |            | AND2 of | AND2 | is  |     |     |     |     |
begin
|     | Z <= | I1  | and | I2 after | 1 ns; |     |     |     |     |     |
| --- | ---- | --- | --- | -------- | ----- | --- | --- | --- | --- | --- |
end AND2;
| architecture |     |     |     | NOR2 of | NOR2 | is  |     |     |     |     |
| ------------ | --- | --- | --- | ------- | ---- | --- | --- | --- | --- | --- |
begin
|     | Z <= | I1  | nor | I2 after | 1 ns; |     |     |     |     |     |
| --- | ---- | --- | --- | -------- | ----- | --- | --- | --- | --- | --- |
end NOR2;
| entity |          | AOI | is  |      |         |     |     |       |     |     |
| ------ | -------- | --- | --- | ---- | ------- | --- | --- | ----- | --- | --- |
|        | port(I1, |     | I2, | I3 : | in BIT; | Z : | out | BIT); |     |     |
end AOI;
| architecture     |           |            |               | structural_view |         | of  | AOI | is     |       |     |
| ---------------- | --------- | ---------- | ------------- | --------------- | ------- | --- | --- | ------ | ----- | --- |
|                  | signal    |            | S1 :          | BIT;            |         |     |     |        |       |     |
|                  | component |            | TWO_INPUT_AND |                 |         |     |     |        |       |     |
|                  | port(IN1, |            |               | IN2:            | in BIT; |     |     |        |       |     |
|                  |           |            | Z_OUT         | : out           | BIT);   |     |     |        |       |     |
|                  | end       | component; |               |                 |         |     |     |        |       |     |
| (cid:13)c CEERI, |           | Pilani     |               |                 |         |     | IC  | Design | Group | 179 |

| VHDL Tutorial    | : Examples |               |           |           |       |     |
| ---------------- | ---------- | ------------- | --------- | --------- | ----- | --- |
| component        |            | TWO_INPUT_NOR |           |           |       |     |
| port(IN1,        |            | IN2           | : in BIT; |           |       |     |
|                  | Z_OUT      | : out         | BIT);     |           |       |     |
| end              | component; |               |           |           |       |     |
| (cid:13)c CEERI, | Pilani     |               |           | IC Design | Group | 180 |

| VHDL | Tutorial          | : Examples      |                 |             |         |         |     |     |     |
| ---- | ----------------- | --------------- | --------------- | ----------- | ------- | ------- | --- | --- | --- |
| --   | configuration     |                 | specification.  |             |         |         |     |     |     |
| --   | port-to-component |                 |                 | pin         |         |         |     |     |     |
| --   | using             | named           | association     |             |         |         |     |     |     |
|      | for U1            | : TWO_INPUT_AND |                 |             |         |         |     |     |     |
|      | use               | entity          | work.AND2(AND2) |             |         |         |     |     |     |
|      | port              | map(I1          | =>              | IN1,        | I2 =>   | IN2,    |     |     |     |
|      |                   |                 |                 |             | Z =>    | Z_OUT); |     |     |     |
| --   | using             | positional      |                 | association |         |         |     |     |     |
|      | for U2            | : TWO_INPUT_NOR |                 |             |         |         |     |     |     |
|      | use               | entity          | work.NOR2(NOR2) |             |         |         |     |     |     |
|      | port              | map(IN1,        |                 | IN2,        | Z_OUT); |         |     |     |     |
begin
| --               | component’s |               | pin-to-signal |             |         |       |           |       |     |
| ---------------- | ----------- | ------------- | ------------- | ----------- | ------- | ----- | --------- | ----- | --- |
| --               | using       | named         | association   |             |         |       |           |       |     |
|                  | U1 :        | TWO_INPUT_AND |               | port        | map(IN1 |       | => I1,    |       |     |
|                  |             |               | IN2           | =>          | I2,     | Z_OUT | => S1);   |       |     |
| --               | using       | positional    |               | association |         |       |           |       |     |
| (cid:13)c CEERI, |             | Pilani        |               |             |         |       | IC Design | Group | 181 |

| VHDL Tutorial | : Examples    |     |              |     |     |     |
| ------------- | ------------- | --- | ------------ | --- | --- | --- |
| U2 :          | TWO_INPUT_NOR |     | port map(S1, | I3, | Z); |     |
end structural_view;
One can also con(cid:2)gure a list of instances of a component using a single con-
| (cid:2)guration | statement. |                 |         |     |     |     |
| --------------- | ---------- | --------------- | ------- | --- | --- | --- |
| for U1,         | U2, U3     | : TWO_INPUT_AND |         |     |     |     |
| use             | entity     | work.AND2(AND2) |         |     |     |     |
| port            | map(IN1,   | IN2,            | Z_OUT); |     |     |     |
One can also con(cid:2)gure all the instances of a component using a single con(cid:2)g-
| uration | statement       |                 |         |     |     |     |
| ------- | --------------- | --------------- | ------- | --- | --- | --- |
| for all | : TWO_INPUT_NOR |                 |         |     |     |     |
| use     | entity          | work.NOR2(NOR2) |         |     |     |     |
| port    | map(IN1,        | IN2,            | Z_OUT); |     |     |     |
After explicitly con(cid:2)guring some of the instances of a component the remaining
instances can be con(cid:2)gured through a single con(cid:2)guration statement.
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 182 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial    | : Examples             |           |       |     |
| ---------------- | ---------------------- | --------- | ----- | --- |
| for others       | : TWO_INPUT_AND        |           |       |     |
| use              | entity work.AND2(AND2) |           |       |     |
| port             | map(IN1, IN2, Z_OUT);  |           |       |     |
| (cid:13)c CEERI, | Pilani                 | IC Design | Group | 183 |

| VHDL Tutorial | : Examples |                           |     |              |     |     |
| ------------- | ---------- | ------------------------- | --- | ------------ | --- | --- |
| Example       | 4 :        | Use of con(cid:2)guration |     | declaration. |     |     |
Note that in Example 3, the con(cid:2)guration of architecture structural view of
entity AOI was done through the use of con(cid:2)guration speci(cid:2)cations. We now
show the use of con(cid:2)guration declaration for con(cid:2)guring the architecture body.
| configuration |                 | NUMBER_1        | of AOI  | is  |     |     |
| ------------- | --------------- | --------------- | ------- | --- | --- | --- |
| for           | STRUCTURAL_VIEW |                 |         |     |     |     |
| for           | U1 :            | TWO_INPUT_AND   |         |     |     |     |
| use           | entity          | work.AND2(AND2) |         |     |     |     |
|               | port map(IN1,   | IN2,            | Z_OUT); |     |     |     |
| end           | for;            | -- U1           |         |     |     |     |
| for           | U2 :            | TWO_INPUT_NOR   |         |     |     |     |
| use           | entity          | work.NOR2(NOR2) |         |     |     |     |
|               | port map(IN1,   | IN2,            | Z_OUT); |     |     |     |
| end           | for;            | -- U2           |         |     |     |     |
| end           | for; --         | STRUCTURAL_VIEW |         |     |     |     |
end NUMBER_1;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 184 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL    | Tutorial : Examples |              |     |     |     |     |     |
| ------- | ------------------- | ------------ | --- | --- | --- | --- | --- |
| Example | 5 : Use             | of generics. |     |     |     |     |     |
Generics are used in VHDL to pass parameter values individually to different
instances of the same component. For example, the gate-delay of the same
gate may be different due to differences in the capacitive loadings of its outputs
| when | it is instanced | at different |     | places | in the | design. |     |
| ---- | --------------- | ------------ | --- | ------ | ------ | ------- | --- |
It is assumed in this example that the following VHDL (cid:2)le containing the vendor-
supplied (or our own) library has already been analyzed into the design library,
work.
| entity             | AND2 is |          |         |       |     |     |     |
| ------------------ | ------- | -------- | ------- | ----- | --- | --- | --- |
| generic(AND2_delay |         | : TIME); |         |       |     |     |     |
| port(I1,           | I2 :    | in BIT;  | Z : out | BIT); |     |     |     |
end AND2;
| entity             | NOR2 is |          |         |           |       |     |     |
| ------------------ | ------- | -------- | ------- | --------- | ----- | --- | --- |
| generic(NOR2_delay |         | : TIME); |         |           |       |     |     |
| port(I1,           | I2 :    | in BIT;  | Z : out | BIT);     |       |     |     |
| (cid:13)c CEERI,   | Pilani  |          |         | IC Design | Group |     | 185 |

| VHDL Tutorial | : Examples |     |     |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
end NOR2;
| architecture |     | AND2 | of  | AND2 | is  |     |     |     |
| ------------ | --- | ---- | --- | ---- | --- | --- | --- | --- |
begin
| Z <= | I1 and | I2  | after | AND2_delay; |     |     |     |     |
| ---- | ------ | --- | ----- | ----------- | --- | --- | --- | --- |
end AND2;
| architecture |     | NOR2 | of  | NOR2 | is  |     |     |     |
| ------------ | --- | ---- | --- | ---- | --- | --- | --- | --- |
begin
| Z <= | I1 nor | I2  | after | NOR2_delay; |     |     |     |     |
| ---- | ------ | --- | ----- | ----------- | --- | --- | --- | --- |
end NOR2;
-----------------------------------------
| entity   | AOI | is     |      |      |     |           |     |     |
| -------- | --- | ------ | ---- | ---- | --- | --------- | --- | --- |
| port(I1, |     | I2, I3 | : in | BIT; | Z : | out BIT); |     |     |
end AOI;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group | 186 |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL             | Tutorial        |            | : Examples      |                     |           |        |     |           |            |       |     |
| ---------------- | --------------- | ---------- | --------------- | ------------------- | --------- | ------ | --- | --------- | ---------- | ----- | --- |
| architecture     |                 |            |                 | structural_generics |           |        |     |           | of AOI     | is    |     |
|                  | signal          |            | S1              | : BIT;              |           |        |     |           |            |       |     |
|                  | component       |            |                 | TWO_INPUT_AND       |           |        |     |           |            |       |     |
|                  | generic(t_delay |            |                 |                     | :         | TIME   | :=  | 2         | ns);       |       |     |
|                  | --              | has        | default         |                     | value     |        | of  | 2 ns      |            |       |     |
|                  | port(IN1,       |            |                 | IN2                 | : in      | BIT;   |     |           |            |       |     |
|                  |                 |            | Z_OUT           | :                   | out BIT); |        |     |           |            |       |     |
|                  | end             | component; |                 |                     |           |        |     |           |            |       |     |
|                  | component       |            |                 | TWO_INPUT_NOR       |           |        |     |           |            |       |     |
|                  | generic(t_delay |            |                 |                     | :         | TIME); |     | --        | no default |       |     |
|                  | port(IN1,       |            |                 | IN2                 | : in      | BIT;   |     |           |            |       |     |
|                  |                 |            | Z_OUT           | :                   | out BIT); |        |     |           |            |       |     |
|                  | end             | component; |                 |                     |           |        |     |           |            |       |     |
|                  | for             | U1         | : TWO_INPUT_AND |                     |           |        |     |           |            |       |     |
|                  | use             | entity     |                 | work.AND2;          |           |        |     |           |            |       |     |
|                  | generic         |            |                 | map(AND2_delay      |           |        | =>  | t_delay); |            |       |     |
|                  | port            |            | map(I1          | =>                  | IN1,      | I2     | =>  | IN2,      |            |       |     |
|                  |                 |            |                 |                     |           | Z      | =>  | Z_OUT);   |            |       |     |
| (cid:13)c CEERI, |                 | Pilani     |                 |                     |           |        |     |           | IC Design  | Group | 187 |

| VHDL Tutorial | :      | Examples       |         |       |          |     |     |
| ------------- | ------ | -------------- | ------- | ----- | -------- | --- | --- |
| for           | U2 :   | TWO_INPUT_NOR  |         |       |          |     |     |
| use           | entity | work.NOR2      |         |       |          |     |     |
| generic       |        | map(NOR2_delay |         | =>    | t_delay) |     |     |
| port          | map(I1 |                | => IN1, | I2 => | IN2,     |     |     |
Z => Z_OUT);
begin
| U1 :    | TWO_INPUT_AND |       |          |               |     |     |     |
| ------- | ------------- | ----- | -------- | ------------- | --- | --- | --- |
| generic |               | map(4 | ns)      | -- optional   |     |     |     |
| port    | map(I1,       |       | I2, S1); |               |     |     |     |
| U2 :    | TWO_INPUT_NOR |       |          |               |     |     |     |
| generic |               | map(4 | ns)      | -- compulsory |     |     |     |
| port    | map(S1,       |       | I3, Z);  |               |     |     |     |
end structural_generics;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 188 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL    | Tutorial | : Examples |      |           |     |       |     |
| ------- | -------- | ---------- | ---- | --------- | --- | ----- | --- |
|         |          |            | IEEE | std logic |     | 1164. |     |
| Example |          | 6 : Use    | of   |           |     |       |     |
| library | IEEE;    |            |      |           |     |       |     |
use IEEE.std_logic_1164.all;
| entity             | AND2 | is                |               |     |     |     |     |
| ------------------ | ---- | ----------------- | ------------- | --- | --- | --- | --- |
| generic(AND2_delay |      |                   | : TIME);      |     |     |     |     |
| port(I1,           |      | I2 :              | in std_logic; |     |     |     |     |
|                    | Z    | : out std_logic); |               |     |     |     |     |
end AND2;
| . .     | . AND2’s | architecture |     | body | . . | .   |     |
| ------- | -------- | ------------ | --- | ---- | --- | --- | --- |
| library | IEEE;    |              |     |      |     |     |     |
use IEEE.std_logic_1164.all;
| entity             | NOR2 | is                |               |     |     |     |     |
| ------------------ | ---- | ----------------- | ------------- | --- | --- | --- | --- |
| generic(NOR2_delay |      |                   | : TIME);      |     |     |     |     |
| port(I1,           |      | I2 :              | in std_logic; |     |     |     |     |
|                    | Z    | : out std_logic); |               |     |     |     |     |
end NOR2;
| . .              | . NOR2’s | architecture |     | body | . . | .            |     |
| ---------------- | -------- | ------------ | --- | ---- | --- | ------------ | --- |
| (cid:13)c CEERI, | Pilani   |              |     |      | IC  | Design Group | 189 |

| VHDL    | Tutorial |       | : Examples |     |     |     |     |     |     |
| ------- | -------- | ----- | ---------- | --- | --- | --- | --- | --- | --- |
| library |          | IEEE; |            |     |     |     |     |     |     |
use IEEE.std_logic_1164.all;
| entity |          | AOI | is    |             |                 |     |     |     |     |
| ------ | -------- | --- | ----- | ----------- | --------------- | --- | --- | --- | --- |
|        | port(I1, |     | I2,   | I3          | : in std_logic; |     |     |     |     |
|        |          | Z   | : out | std_logic); |                 |     |     |     |     |
end AOI;
| architecture     |                 |            |               | structural_ieee |                 | of  | AOI is    |       |     |
| ---------------- | --------------- | ---------- | ------------- | --------------- | --------------- | --- | --------- | ----- | --- |
|                  | signal          |            | S1 :          | std_logic;      |                 |     |           |       |     |
|                  | component       |            | TWO_INPUT_AND |                 |                 |     |           |       |     |
|                  | generic(t_delay |            |               |                 | : TIME);        |     |           |       |     |
|                  | port(IN1,       |            |               | IN2             | : in std_logic; |     |           |       |     |
|                  |                 |            | Z_OUT         | : out           | std_logic);     |     |           |       |     |
|                  | end             | component; |               |                 |                 |     |           |       |     |
|                  | component       |            | TWO_INPUT_NOR |                 |                 |     |           |       |     |
|                  | generic(t_delay |            |               |                 | : TIME);        |     |           |       |     |
|                  | port(IN1,       |            |               | IN2             | : in std_logic; |     |           |       |     |
|                  |                 |            | Z_OUT         | : out           | std_logic);     |     |           |       |     |
|                  | end             | component; |               |                 |                 |     |           |       |     |
| (cid:13)c CEERI, |                 | Pilani     |               |                 |                 |     | IC Design | Group | 190 |

| VHDL Tutorial | :      | Examples       |         |       |          |     |     |
| ------------- | ------ | -------------- | ------- | ----- | -------- | --- | --- |
| for           | U1 :   | TWO_INPUT_AND  |         |       |          |     |     |
| use           | entity | work.AND2      |         |       |          |     |     |
| generic       |        | map(AND2_delay |         | =>    | t_delay) |     |     |
| port          | map(I1 |                | => IN1, | I2 => | IN2,     |     |     |
Z => Z_OUT);
| for     | U2 :   | TWO_INPUT_NOR  |         |       |          |     |     |
| ------- | ------ | -------------- | ------- | ----- | -------- | --- | --- |
| use     | entity | work.NOR2      |         |       |          |     |     |
| generic |        | map(NOR2_delay |         | =>    | t_delay) |     |     |
| port    | map(I1 |                | => IN1, | I2 => | IN2,     |     |     |
Z => Z_OUT);
begin
| U1 :    | TWO_INPUT_AND |       |          |     |     |     |     |
| ------- | ------------- | ----- | -------- | --- | --- | --- | --- |
| generic |               | map(4 | ns)      |     |     |     |     |
| port    | map(I1,       |       | I2, S1); |     |     |     |     |
| U2 :    | TWO_INPUT_NOR |       |          |     |     |     |     |
| generic |               | map(4 | ns)      |     |     |     |     |
| port    | map(S1,       |       | I3, Z);  |     |     |     |     |
end structural_ieee;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 191 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL   | Tutorial |     | : Examples |                |     |     |            |          |     |                   |     |
| ------ | -------- | --- | ---------- | -------------- | --- | --- | ---------- | -------- | --- | ----------------- | --- |
|        |          |     |            |                |     |     | Gate-Level |          |     | Modeling          |     |
| Choice |          | of  | data       | representation |     |     | for        | modeling |     | of functionality. |     |
(cid:15) A variety of multi-valued logic models are possible :
|                  | Prede(cid:2)ned |        |      | type |       | BIT : ’0’, |      | ’1’       |      |       |     |
| ---------------- | --------------- | ------ | ---- | ---- | ----- | ---------- | ---- | --------- | ---- | ----- | --- |
|                  | Four-valued     |        |      |      | Logic | : (’X’,    |      | ’0’,      | ’1’, | ’Z’)  |     |
|                  | Seven-valued    |        |      |      | Logic | :          |      |           |      |       |     |
|                  | (’X’,           |        | ’0’, |      | ’1’,  | ’Z’,       | ’W’, |           | ’L’, | ’H’)  |     |
| (cid:13)c CEERI, |                 | Pilani |      |      |       |            |      | IC Design |      | Group | 192 |

| VHDL             | Tutorial       |                 | : Examples |           |                |       |        |       |               |     |       |       |       |       |     |
| ---------------- | -------------- | --------------- | ---------- | --------- | -------------- | ----- | ------ | ----- | ------------- | --- | ----- | ----- | ----- | ----- | --- |
| (cid:15)         | State-Strength |                 |            |           |                | model | :      |       |               |     |       |       |       |       |     |
|                  |                | (cid:150) Three |            | States    |                | :     | ’0’,   | ’X’,  | ’1’           |     |       |       |       |       |     |
|                  |                | (cid:150) Three |            | Strengths |                |       | : ’F’, |       | ’R’,          | ’Z’ |       |       |       |       |     |
|                  | Nine-valued    |                 |            |           | Logic          |       | :      |       |               |     |       |       |       |       |     |
|                  | ("F0",         |                 |            | "FX",     |                | "F1", |        | "R0", | "RX",         |     | "R1", | "Z0", | "ZX", | "Z1") |     |
| (cid:15)         | Generalized    |                 |            |           | state-strength |       |        |       | model         | :   |       |       |       |       |     |
|                  | Three          |                 | states,    |           | Any            |       | number |       | of strengths. |     |       |       |       |       |     |
| (cid:13)c CEERI, |                | Pilani          |            |           |                |       |        |       | IC Design     |     | Group |       |       |       | 193 |

| VHDL     | Tutorial | : Examples |      |     |     |     |     |     |     |
| -------- | -------- | ---------- | ---- | --- | --- | --- | --- | --- | --- |
| (cid:15) | IEEE     | std logic  | 1164 |     |     |     |     |     |     |
:
This is the industry-standard package for simulation and synthesis. It de-
|     | (cid:2)nes | the type | std ulogic |     | as  | :   |     |     |     |
| --- | ---------- | -------- | ---------- | --- | --- | --- | --- | --- | --- |
type std_ulogic is (’U’, ’X’, ’0’, ’1’, ’Z’, ’W’, ’L’, ’H’, ’-’);
Its resolved subtype, std logic, is the preferred type for modeling.
|     | (cid:150) ’U’ | is output         | of all        | uninitialized |       |           | storage | node.     |     |
| --- | ------------- | ----------------- | ------------- | ------------- | ----- | --------- | ------- | --------- | --- |
|     | (cid:150) ’-’ | is (cid:147)don’t | care(cid:148) | for           | logic | synthesis |         | purposes. |     |
(cid:15)
|                  | Interval | Logic |     |     |     |           |       |     |     |
| ---------------- | -------- | ----- | --- | --- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani   |       |     |     |     | IC Design | Group |     | 194 |

| VHDL Tutorial | : Examples |     |       |          |          |     |
| ------------- | ---------- | --- | ----- | -------- | -------- | --- |
|               |            |     | VITAL | Modeling | Standard |     |
IEEE standard 1076.4 (Standard VITAL ASIC Modeling Speci(cid:2)cation) provides
a standard for the usage of the VHDL language and modeling style for modeling
| ASIC | libraries. |     |     |     |     |     |
| ---- | ---------- | --- | --- | --- | --- | --- |
It permits back-annotation of post-route SDF delay data onto a structural VHDL
model via the use of generics in an automated way (through the development
| of tools         | for this | purpose | based | on the    | standard). |     |
| ---------------- | -------- | ------- | ----- | --------- | ---------- | --- |
| (cid:13)c CEERI, | Pilani   |         |       | IC Design | Group      | 195 |

| VHDL Tutorial | : Examples |     |           |          |     |     |
| ------------- | ---------- | --- | --------- | -------- | --- | --- |
|               |            |     | Data-Flow | Modeling |     |     |
Modeling of hardware as a (cid:3)ow of data through stages (or a network) of oper-
| ators | which modify | the data | as it (cid:3)ows | through | them. |     |
| ----- | ------------ | -------- | ---------------- | ------- | ----- | --- |
It is a convenient way of specifying processing on data (which implies a net-
| work | of logic gates). |     |     |     |     |     |
| ---- | ---------------- | --- | --- | --- | --- | --- |
Logic synthesis tools can take a data-(cid:3)ow description and convert it into a
structural description (comprising of an interconnection of available gates in a
| target           | library). |     |           |       |     |     |
| ---------------- | --------- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani    |     | IC Design | Group |     | 196 |

| VHDL    | Tutorial | : Examples |     |     |     |     |     |     |
| ------- | -------- | ---------- | --- | --- | --- | --- | --- | --- |
| Example |          | :          |     |     |     |     |     |     |
In data-(cid:3)ow modeling, concurrent signal assignment statements are used to
model the processing of inputs through a set of processing stages (modeled
| using    | operators |     | of the  | language). |     |           |     |     |
| -------- | --------- | --- | ------- | ---------- | --- | --------- | --- | --- |
| entity   | AOI       | is  |         |            |     |           |     |     |
| port(I1, |           | I2, | I3 : in | BIT;       | Z : | out BIT); |     |     |
end AOI;
| architecture |     |     | data_flow1 | of  | AOI | is  |     |     |
| ------------ | --- | --- | ---------- | --- | --- | --- | --- | --- |
| signal       |     | S1, | S2 : BIT;  |     |     |     |     |     |
begin
| S1  | <= I1  | and | I2; |     |     |     |     |     |
| --- | ------ | --- | --- | --- | --- | --- | --- | --- |
| S2  | <= S1  | or  | I3; |     |     |     |     |     |
| Z   | <= not | S2; |     |     |     |     |     |     |
end data_flow1;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group | 197 |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial |     | : Examples |     |     |     |     |     |     |
| ------------- | --- | ---------- | --- | --- | --- | --- | --- | --- |
Since the order of concurrent statements is not important, the model below is
| identical |     | to the | one above. |      |     |           |     |     |
| --------- | --- | ------ | ---------- | ---- | --- | --------- | --- | --- |
| entity    | AOI | is     |            |      |     |           |     |     |
| port(I1,  |     | I2,    | I3 : in    | BIT; | Z : | out BIT); |     |     |
end AOI;
| architecture |     |     | data_flow2 | of  | AOI | is  |     |     |
| ------------ | --- | --- | ---------- | --- | --- | --- | --- | --- |
| signal       |     | S1, | S2 : BIT;  |     |     |     |     |     |
begin
| Z <=  | not | S2; |     |     |     |     |     |     |
| ----- | --- | --- | --- | --- | --- | --- | --- | --- |
| S2 <= | S1  | or  | I3; |     |     |     |     |     |
| S1 <= | I1  | and | I2; |     |     |     |     |     |
end data_flow2;
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC Design | Group | 198 |
| ---------------- | ------ | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |                   |       |       |          |     |
| ------------- | ---------- | ----------------- | ----- | ----- | -------- | --- |
|               |            | Register-Transfer | Level | (RTL) | Modeling |     |
Modeling of hardware as a succession of elementary processing steps se-
quenced by a controller, such that during each step data from speci(cid:2)c storage
registers is transferred to the inputs of the processing elements and the outputs
of the processing elements are stored in registers at the end of the step.
Transitions of a clock signal (which can be single-phase clock or multi-phase
clock) indicate the starting-time and ending-time for a processing step.
| (cid:13)c CEERI, | Pilani |     | IC Design | Group |     | 199 |
| ---------------- | ------ | --- | --------- | ----- | --- | --- |

| VHDL | Tutorial | : Examples |     |     |     |     |     |     |     |
| ---- | -------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
Example 1 : RTL model of a watch (mixed control and datapath).
| package |      | CLOCK_TYPES  |     |     | is       |      |        |     |     |
| ------- | ---- | ------------ | --- | --- | -------- | ---- | ------ | --- | --- |
|         | type | HOURS_TYPE   |     | is  | range    | 1 to | 12;    |     |     |
|         | type | MINUTES_TYPE |     |     | is range | 0    | to 59; |     |     |
|         | type | SECONDS_TYPE |     |     | is range | 0    | to 59; |     |     |
end CLOCK_TYPES;
use work.CLOCK_TYPES.all;
| entity |             | WATCH   | is    |     |                |      |     |     |     |
| ------ | ----------- | ------- | ----- | --- | -------------- | ---- | --- | --- | --- |
|        | port(CLOCK, |         | RESET |     | : in           | BIT; |     |     |     |
|        |             | HOURS   | : out |     | HOURS_TYPE;    |      |     |     |     |
|        |             | MINUTES | :     | out | MINUTES_TYPE;  |      |     |     |     |
|        |             | SECONDS | :     | out | SECONDS_TYPE); |      |     |     |     |
end WATCH;
| architecture |     |     | RTL_1 |     | of WATCH | is  |     |     |     |
| ------------ | --- | --- | ----- | --- | -------- | --- | --- | --- | --- |
begin
|                  | process(CLOCK, |        |           | RESET) |     |             |           |       |     |
| ---------------- | -------------- | ------ | --------- | ------ | --- | ----------- | --------- | ----- | --- |
|                  | variable       |        | HOURS_REG |        | :   | HOURS_TYPE; |           |       |     |
| (cid:13)c CEERI, |                | Pilani |           |        |     |             | IC Design | Group | 200 |

| VHDL | Tutorial | :   | Examples     |     |         |     |               |     |     |       |     |
| ---- | -------- | --- | ------------ | --- | ------- | --- | ------------- | --- | --- | ----- | --- |
|      | variable |     | MINUTES_REG  |     |         | :   | MINUTES_TYPE; |     |     |       |     |
|      | variable |     | SECONDS_REG  |     |         | :   | SECONDS_TYPE; |     |     |       |     |
|      | variable |     | HOURS_CARRY, |     |         |     | MINUTES_CARRY |     |     | :     |     |
|      |          |     |              |     | integer |     | range         |     | 0   | to 1; |     |
begin
|     | if (RESET     |              | = ’0’) |     | then        |       |      |     |      |      |     |
| --- | ------------- | ------------ | ------ | --- | ----------- | ----- | ---- | --- | ---- | ---- | --- |
|     | HOURS_REG     |              | :=     | 12; |             |       |      |     |      |      |     |
|     | MINUTES_REG   |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | SECONDS_REG   |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | elsif         | (CLOCK’event |        |     | and         | CLOCK |      | =   | ’1’) | then |     |
|     | MINUTES_CARRY |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | HOURS_CARRY   |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | if            | (SECONDS_REG |        |     | /=          | 59)   | then |     |      |      |     |
|     |               | SECONDS_REG  |        | :=  | SECONDS_REG |       |      |     | + 1; |      |     |
else
|                  |     | SECONDS_REG     |     | :=  | 0;  |     |      |      |           |       |     |
| ---------------- | --- | --------------- | --- | --- | --- | --- | ---- | ---- | --------- | ----- | --- |
|                  |     | MINUTES_CARRY   |     |     | :=  | 1;  |      |      |           |       |     |
|                  | end | if;             |     |     |     |     |      |      |           |       |     |
|                  | if  | (MINUTES_CARRY  |     |     | =   | 1)  | then |      |           |       |     |
|                  |     | if (MINUTES_REG |     |     | /=  | 59) |      | then |           |       |     |
| (cid:13)c CEERI, |     | Pilani          |     |     |     |     |      |      | IC Design | Group | 201 |

| VHDL | Tutorial : Examples |                |     |      |     |     |
| ---- | ------------------- | -------------- | --- | ---- | --- | --- |
|      | MINUTES_REG         | := MINUTES_REG |     | + 1; |     |     |
else
|     | MINUTES_REG | := 0; |     |     |     |     |
| --- | ----------- | ----- | --- | --- | --- | --- |
|     | HOURS_CARRY | := 1; |     |     |     |     |
end if;
|     | end if;         |              |      |      |     |     |
| --- | --------------- | ------------ | ---- | ---- | --- | --- |
|     | if (HOURS_CARRY | = 1)         | then |      |     |     |
|     | if (HOURS_REG   | /= 12)       | then |      |     |     |
|     | HOURS_REG       | := HOURS_REG |      | + 1; |     |     |
else
|     | HOURS_REG | := 1; |     |     |     |     |
| --- | --------- | ----- | --- | --- | --- | --- |
end if;
|         | end if;         |     |     |     |     |     |
| ------- | --------------- | --- | --- | --- | --- | --- |
| end     | if;             |     |     |     |     |     |
| HOURS   | <= HOURS_REG;   |     |     |     |     |     |
| MINUTES | <= MINUTES_REG; |     |     |     |     |     |
| SECONDS | <= SECONDS_REG; |     |     |     |     |     |
| end     | process;        |     |     |     |     |     |
end RTL_1;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 202 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL    | Tutorial | : Examples   |             |     |          |       |        |        |     |
| ------- | -------- | ------------ | ----------- | --- | -------- | ----- | ------ | ------ | --- |
| Example |          | 2            | : Alternate |     | RTL      | model | of a   | watch. |     |
| package |          | CLOCK_TYPES  |             |     | is       |       |        |        |     |
|         | type     | HOURS_TYPE   |             | is  | range    | 1 to  | 12;    |        |     |
|         | type     | MINUTES_TYPE |             |     | is range | 0     | to 59; |        |     |
|         | type     | SECONDS_TYPE |             |     | is range | 0     | to 59; |        |     |
end CLOCK_TYPES;
use work.CLOCK_TYPES.all;
| entity |             | WATCH   | is    |     |                |      |     |     |     |
| ------ | ----------- | ------- | ----- | --- | -------------- | ---- | --- | --- | --- |
|        | port(CLOCK, |         | RESET |     | : in           | BIT; |     |     |     |
|        |             | HOURS   | : out |     | HOURS_TYPE;    |      |     |     |     |
|        |             | MINUTES | :     | out | MINUTES_TYPE;  |      |     |     |     |
|        |             | SECONDS | :     | out | SECONDS_TYPE); |      |     |     |     |
end WATCH;
| architecture |     |     | RTL_2 |     | of WATCH | is  |     |     |     |
| ------------ | --- | --- | ----- | --- | -------- | --- | --- | --- | --- |
begin
|                  | process(CLOCK, |        |           | RESET) |     |             |           |       |     |
| ---------------- | -------------- | ------ | --------- | ------ | --- | ----------- | --------- | ----- | --- |
|                  | variable       |        | HOURS_REG |        | :   | HOURS_TYPE; |           |       |     |
| (cid:13)c CEERI, |                | Pilani |           |        |     |             | IC Design | Group | 203 |

| VHDL | Tutorial | :   | Examples     |     |         |     |               |     |     |       |     |
| ---- | -------- | --- | ------------ | --- | ------- | --- | ------------- | --- | --- | ----- | --- |
|      | variable |     | MINUTES_REG  |     |         | :   | MINUTES_TYPE; |     |     |       |     |
|      | variable |     | SECONDS_REG  |     |         | :   | SECONDS_TYPE; |     |     |       |     |
|      | variable |     | HOURS_CARRY, |     |         |     | MINUTES_CARRY |     |     | :     |     |
|      |          |     |              |     | integer |     | range         |     | 0   | to 1; |     |
begin
|     | if (RESET     |              | = ’0’) |     | then        |       |      |     |      |      |     |
| --- | ------------- | ------------ | ------ | --- | ----------- | ----- | ---- | --- | ---- | ---- | --- |
|     | HOURS         |              | <= 12; |     |             |       |      |     |      |      |     |
|     | MINUTES       |              | <= 0;  |     |             |       |      |     |      |      |     |
|     | SECONDS       |              | <= 0;  |     |             |       |      |     |      |      |     |
|     | elsif         | (CLOCK’event |        |     | and         | CLOCK |      | =   | ’1’) | then |     |
|     | MINUTES_CARRY |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | HOURS_CARRY   |              |        | :=  | 0;          |       |      |     |      |      |     |
|     | if            | (SECONDS_REG |        |     | /=          | 59)   | then |     |      |      |     |
|     |               | SECONDS_REG  |        | :=  | SECONDS_REG |       |      |     | + 1; |      |     |
else
|                  |     | SECONDS_REG     |     | :=  | 0;  |     |      |      |           |       |     |
| ---------------- | --- | --------------- | --- | --- | --- | --- | ---- | ---- | --------- | ----- | --- |
|                  |     | MINUTES_CARRY   |     |     | :=  | 1;  |      |      |           |       |     |
|                  | end | if;             |     |     |     |     |      |      |           |       |     |
|                  | if  | (MINUTES_CARRY  |     |     | =   | 1)  | then |      |           |       |     |
|                  |     | if (MINUTES_REG |     |     | /=  | 59) |      | then |           |       |     |
| (cid:13)c CEERI, |     | Pilani          |     |     |     |     |      |      | IC Design | Group | 204 |

| VHDL | Tutorial : Examples |                |     |      |     |     |
| ---- | ------------------- | -------------- | --- | ---- | --- | --- |
|      | MINUTES_REG         | := MINUTES_REG |     | + 1; |     |     |
else
|     | MINUTES_REG | := 0; |     |     |     |     |
| --- | ----------- | ----- | --- | --- | --- | --- |
|     | HOURS_CARRY | := 1; |     |     |     |     |
end if;
|     | end if;         |              |      |      |     |     |
| --- | --------------- | ------------ | ---- | ---- | --- | --- |
|     | if (HOURS_CARRY | = 1)         | then |      |     |     |
|     | if (HOURS_REG   | /= 12)       | then |      |     |     |
|     | HOURS_REG       | := HOURS_REG |      | + 1; |     |     |
else
|     | HOURS_REG | := 1; |     |     |     |     |
| --- | --------- | ----- | --- | --- | --- | --- |
end if;
|     | end if;                 |     |     |     |     |     |
| --- | ----------------------- | --- | --- | --- | --- | --- |
|     | HOURS <= HOURS_REG;     |     |     |     |     |     |
|     | MINUTES <= MINUTES_REG; |     |     |     |     |     |
|     | SECONDS <= SECONDS_REG; |     |     |     |     |     |
| end | if;                     |     |     |     |     |     |
| end | process;                |     |     |     |     |     |
end RTL_2;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 205 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
Example 3 : Another RTL model of a watch (separate sequential and combi-
| national | parts).      |     |     |          |      |        |     |     |
| -------- | ------------ | --- | --- | -------- | ---- | ------ | --- | --- |
| package  | CLOCK_TYPES  |     |     | is       |      |        |     |     |
| type     | HOURS_TYPE   |     | is  | range    | 1 to | 12;    |     |     |
| type     | MINUTES_TYPE |     |     | is range | 0    | to 59; |     |     |
| type     | SECONDS_TYPE |     |     | is range | 0    | to 59; |     |     |
end CLOCK_TYPES;
use work.CLOCK_TYPES.all;
| entity      | WATCH   | is      |       |                |      |     |     |     |
| ----------- | ------- | ------- | ----- | -------------- | ---- | --- | --- | --- |
| port(CLOCK, |         | RESET   |       | : in           | BIT; |     |     |     |
|             | HOURS   | : inout |       | HOURS_TYPE;    |      |     |     |     |
|             | MINUTES | :       | inout | MINUTES_TYPE;  |      |     |     |     |
|             | SECONDS | :       | inout | SECONDS_TYPE); |      |     |     |     |
end WATCH;
| architecture     |              | RTL_3 | of  | WATCH           | is  |           |       |     |
| ---------------- | ------------ | ----- | --- | --------------- | --- | --------- | ----- | --- |
| signal           | HOURS_next   |       |     | : HOURS_TYPE;   |     |           |       |     |
| signal           | MINUTES_next |       |     | : MINUTES_TYPE; |     |           |       |     |
| (cid:13)c CEERI, | Pilani       |       |     |                 |     | IC Design | Group | 206 |

| VHDL   | Tutorial :   | Examples |     |                 |     |     |     |
| ------ | ------------ | -------- | --- | --------------- | --- | --- | --- |
| signal | SECONDS_next |          |     | : SECONDS_TYPE; |     |     |     |
begin
| SEQ | : process(CLOCK, |     |     | RESET) |     |     |     |
| --- | ---------------- | --- | --- | ------ | --- | --- | --- |
begin
| if    | (RESET           | = ’0’)           | then |           |          |      |     |
| ----- | ---------------- | ---------------- | ---- | --------- | -------- | ---- | --- |
|       | HOURS            | <= 12;           |      |           |          |      |     |
|       | MINUTES          | <= 0;            |      |           |          |      |     |
|       | SECONDS          | <= 0;            |      |           |          |      |     |
| elsif | (CLOCK’event     |                  |      | and CLOCK | = ’1’)   | then |     |
|       | HOURS            | <= HOURS_next;   |      |           |          |      |     |
|       | MINUTES          | <= MINUTES_next; |      |           |          |      |     |
|       | SECONDS          | <= SECONDS_next; |      |           |          |      |     |
| end   | if;              |                  |      |           |          |      |     |
| end   | process          | SEQ;             |      |           |          |      |     |
| COMBI | : process(HOURS, |                  |      | MINUTES,  | SECONDS) |      |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 207 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial      | : Examples   |              |     |         |         |               |       |      |     |     |
| ---- | ------------- | ------------ | ------------ | --- | ------- | ------- | ------------- | ----- | ---- | --- | --- |
|      | variable      |              | HOURS_CARRY, |     |         |         | MINUTES_CARRY |       |      | :   |     |
|      |               |              |              |     | integer |         |               | range | 0 to | 1;  |     |
|      | MINUTES_CARRY |              |              |     | :=      | 0;      |               |       |      |     |     |
|      | HOURS_CARRY   |              |              | :=  | 0;      |         |               |       |      |     |     |
|      | if            | (SECONDS     |              | /=  | 59)     | then    |               |       |      |     |     |
|      |               | SECONDS_next |              |     | <=      | SECONDS |               | +     | 1;   |     |     |
else
|     |     | SECONDS_next   |     |     | <=  | 0;  |         |     |      |     |     |
| --- | --- | -------------- | --- | --- | --- | --- | ------- | --- | ---- | --- | --- |
|     |     | MINUTES_CARRY  |     |     | :=  | 1;  |         |     |      |     |     |
|     | end | if;            |     |     |     |     |         |     |      |     |     |
|     | if  | (MINUTES_CARRY |     |     |     | =   | 1) then |     |      |     |     |
|     |     | if (MINUTES    |     |     | /=  | 59) | then    |     |      |     |     |
|     |     | MINUTES_next   |     |     |     | <=  | MINUTES |     | + 1; |     |     |
else
|                  |     | MINUTES_next |     |     |     | <=  | 0;   |     |           |       |     |
| ---------------- | --- | ------------ | --- | --- | --- | --- | ---- | --- | --------- | ----- | --- |
|                  |     | HOURS_CARRY  |     |     | :=  | 1;  |      |     |           |       |     |
|                  |     | end if;      |     |     |     |     |      |     |           |       |     |
|                  | end | if;          |     |     |     |     |      |     |           |       |     |
|                  | if  | (HOURS_CARRY |     |     | =   | 1)  | then |     |           |       |     |
| (cid:13)c CEERI, |     | Pilani       |     |     |     |     |      |     | IC Design | Group | 208 |

| VHDL | Tutorial : Examples |        |            |     |     |     |
| ---- | ------------------- | ------ | ---------- | --- | --- | --- |
|      | if (HOURS           | /= 12) | then       |     |     |     |
|      | HOURS_next          | <=     | HOURS + 1; |     |     |     |
else
|     | HOURS_next | <=  | 1;  |     |     |     |
| --- | ---------- | --- | --- | --- | --- | --- |
end if;
|     | end if; |        |     |     |     |     |
| --- | ------- | ------ | --- | --- | --- | --- |
| end | if;     |        |     |     |     |     |
| end | process | COMBI; |     |     |     |     |
end RTL_3;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 209 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples   |       |          |       |       |        |          |     |
| ------------- | ------------ | ----- | -------- | ----- | ----- | ------ | -------- | --- |
| Example       | 4            | : Yet | another  | RTL   | model | of     | a watch. |     |
| package       | CLOCK_TYPES  |       | is       |       |       |        |          |     |
| type          | HOURS_TYPE   |       | is range |       | 1 to  | 12;    |          |     |
| type          | MINUTES_TYPE |       | is       | range | 0     | to 59; |          |     |
| type          | SECONDS_TYPE |       | is       | range | 0     | to 59; |          |     |
end CLOCK_TYPES;
use work.CLOCK_TYPES.all;
| entity      | WATCH   | is    |                    |      |     |     |     |     |
| ----------- | ------- | ----- | ------------------ | ---- | --- | --- | --- | --- |
| port(CLOCK, |         | RESET | : in               | BIT; |     |     |     |     |
|             | HOURS   | : out | HOURS_TYPE;        |      |     |     |     |     |
|             | MINUTES | :     | out MINUTES_TYPE;  |      |     |     |     |     |
|             | SECONDS | :     | out SECONDS_TYPE); |      |     |     |     |     |
end WATCH;
| architecture     |             | RTL_4 | of WATCH      |               | is  |           |       |     |
| ---------------- | ----------- | ----- | ------------- | ------------- | --- | --------- | ----- | --- |
| signal           | HOURS_REG   |       | : HOURS_TYPE; |               |     |           |       |     |
| signal           | MINUTES_REG |       | :             | MINUTES_TYPE; |     |           |       |     |
| signal           | SECONDS_REG |       | :             | SECONDS_TYPE; |     |           |       |     |
| (cid:13)c CEERI, | Pilani      |       |               |               |     | IC Design | Group | 210 |

| VHDL | Tutorial | :   | Examples |     |     |     |     |     |     |     |
| ---- | -------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
begin
|     | process(CLOCK, |     |              | RESET) |         |               |     |     |       |     |
| --- | -------------- | --- | ------------ | ------ | ------- | ------------- | --- | --- | ----- | --- |
|     | variable       |     | HOURS_CARRY, |        |         | MINUTES_CARRY |     |     | :     |     |
|     |                |     |              |        | integer | range         |     | 0   | to 1; |     |
begin
|     | if (RESET     |              | = ’0’) |     | then        |       |     |      |      |     |
| --- | ------------- | ------------ | ------ | --- | ----------- | ----- | --- | ---- | ---- | --- |
|     | HOURS_REG     |              | <=     | 12; |             |       |     |      |      |     |
|     | MINUTES_REG   |              |        | <=  | 0;          |       |     |      |      |     |
|     | SECONDS_REG   |              |        | <=  | 0;          |       |     |      |      |     |
|     | elsif         | (CLOCK’event |        |     | and         | CLOCK | =   | ’1’) | then |     |
|     | MINUTES_CARRY |              |        | :=  | 0;          |       |     |      |      |     |
|     | HOURS_CARRY   |              |        | :=  | 0;          |       |     |      |      |     |
|     | if            | (SECONDS_REG |        |     | /= 59)      | then  |     |      |      |     |
|     |               | SECONDS_REG  |        | <=  | SECONDS_REG |       |     | + 1; |      |     |
else
|                  |     | SECONDS_REG    |     | <=  | 0;    |         |     |           |       |     |
| ---------------- | --- | -------------- | --- | --- | ----- | ------- | --- | --------- | ----- | --- |
|                  |     | MINUTES_CARRY  |     |     | := 1; |         |     |           |       |     |
|                  | end | if;            |     |     |       |         |     |           |       |     |
|                  | if  | (MINUTES_CARRY |     |     | =     | 1) then |     |           |       |     |
| (cid:13)c CEERI, |     | Pilani         |     |     |       |         |     | IC Design | Group | 211 |

| VHDL | Tutorial : Examples |                |          |      |     |     |
| ---- | ------------------- | -------------- | -------- | ---- | --- | --- |
|      | if (MINUTES_REG     | /=             | 59) then |      |     |     |
|      | MINUTES_REG         | <= MINUTES_REG |          | + 1; |     |     |
else
|     | MINUTES_REG | <= 0; |     |     |     |     |
| --- | ----------- | ----- | --- | --- | --- | --- |
|     | HOURS_CARRY | := 1; |     |     |     |     |
end if;
|     | end if;         |              |      |      |     |     |
| --- | --------------- | ------------ | ---- | ---- | --- | --- |
|     | if (HOURS_CARRY | = 1)         | then |      |     |     |
|     | if (HOURS_REG   | /= 12)       | then |      |     |     |
|     | HOURS_REG       | <= HOURS_REG |      | + 1; |     |     |
else
|     | HOURS_REG | <= 1; |     |     |     |     |
| --- | --------- | ----- | --- | --- | --- | --- |
end if;
|         | end if;         |     |     |     |     |     |
| ------- | --------------- | --- | --- | --- | --- | --- |
| end     | if;             |     |     |     |     |     |
| end     | process;        |     |     |     |     |     |
| HOURS   | <= HOURS_REG;   |     |     |     |     |     |
| MINUTES | <= MINUTES_REG; |     |     |     |     |     |
| SECONDS | <= SECONDS_REG; |     |     |     |     |     |
end RTL_4;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 212 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |       |          |     |     |
| ------------- | ---------- | --- | --- | ----- | -------- | --- | --- |
|               |            |     |     | Error | Checking |     |     |
Checking setup, hold and recovery time violations for a positive-edge triggered
| D (cid:3)ip-(cid:3)op | with | asynchronous |     | active-low |     | clear. |     |
| --------------------- | ---- | ------------ | --- | ---------- | --- | ------ | --- |
Example : Making use of passive processes in entity declarations for building
checks.
| entity          | D_FF      | is       |          |      |      |     |     |
| --------------- | --------- | -------- | -------- | ---- | ---- | --- | --- |
| generic(TSETUP, |           |          | THOLD,   |      |      |     |     |
|                 | TRECOVERY |          | : TIME   | := 0 | ns); |     |     |
| port(D,         | CLK       | : in     | BIT :=   | ’0’; |      |     |     |
|                 | CLR       | : in BIT | := ’1’;  |      |      |     |     |
|                 | Q :       | out BIT  | := ’0’;  |      |      |     |     |
|                 | QB :      | out BIT  | := ’1’); |      |      |     |     |
begin
| CHECKS           | :      | process(D, | CLK, | CLR) |           |       |     |
| ---------------- | ------ | ---------- | ---- | ---- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |            |      |      | IC Design | Group | 213 |

| VHDL | Tutorial | :   | Examples |     |     |     |     |     |     |     |
| ---- | -------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
begin
|     | if  | (not     | CLK’stable        |      | and  | CLK                    | = ’1’) |      | then |     |
| --- | --- | -------- | ----------------- | ---- | ---- | ---------------------- | ------ | ---- | ---- | --- |
|     |     | assert   | D’stable(TSETUP)  |      |      |                        |        |      |      |     |
|     |     | report   | "Setup            | Time |      | Violation"             |        |      |      |     |
|     |     | severity | warning;          |      |      |                        |        |      |      |     |
|     | end | if;      |                   |      |      |                        |        |      |      |     |
|     | if  | (not     | D’stable          |      | and  | CLK                    | = ’1’) | then |      |     |
|     |     | assert   | CLK’stable(THOLD) |      |      |                        |        |      |      |     |
|     |     | report   | "Hold             | Time |      | Violation"             |        |      |      |     |
|     |     | severity | warning;          |      |      |                        |        |      |      |     |
|     | end | if;      |                   |      |      |                        |        |      |      |     |
|     | if  | (not     | CLK’stable        |      | and  | CLK                    | = ’1’) |      | then |     |
|     |     | assert   | (CLR              | = 1  | and  | CLR’stable(TRECOVERY)) |        |      |      |     |
|     |     | report   | "Recovery         |      | Time | Violation"             |        |      |      |     |
|     |     | severity | warning;          |      |      |                        |        |      |      |     |
|     | end | if;      |                   |      |      |                        |        |      |      |     |
|     | end | process  | CHECKS;           |      |      |                        |        |      |      |     |
end D_FF;
| (cid:13)c CEERI, |     | Pilani |     |     |     |     | IC  | Design | Group | 214 |
| ---------------- | --- | ------ | --- | --- | --- | --- | --- | ------ | ----- | --- |

| VHDL Tutorial |     | : Examples |     |     |     |        |     |          |     |     |        |     |
| ------------- | --- | ---------- | --- | --- | --- | ------ | --- | -------- | --- | --- | ------ | --- |
|               |     |            |     |     |     | Mixing |     | Modeling |     |     | Styles |     |
One can freely mix process statements, concurrent signal assignment state-
ments / block statements and component instantiations / generate state-
| ments   | to         | build | a   | single | architecture |     |     |     | body. |     |     |     |
| ------- | ---------- | ----- | --- | ------ | ------------ | --- | --- | --- | ----- | --- | --- | --- |
| Example |            | :     |     |        |              |     |     |     |       |     |     |     |
| entity  | FULL_ADDER |       |     | is     |              |     |     |     |       |     |     |     |
| port(A, |            | B,    | CIN | : in   | BIT;         |     |     |     |       |     |     |     |
|         | SUM,       | COUT  |     | : out  | BIT);        |     |     |     |       |     |     |     |
end FULL_ADDER;
| architecture |     |      | MIXED_ONE |      | of   | FULL_ADDER |     |     | is    |     |     |     |
| ------------ | --- | ---- | --------- | ---- | ---- | ---------- | --- | --- | ----- | --- | --- | --- |
| component    |     | NOR3 |           |      |      |            |     |     |       |     |     |     |
| port(I1,     |     | I2,  | I3        | : in | BIT; |            | O : | out | BIT); |     |     |     |
end component;
| signal           |        | C1, | C2, | C3, | HALF_SUM |     | :   | BIT; |        |       |     |     |
| ---------------- | ------ | --- | --- | --- | -------- | --- | --- | ---- | ------ | ----- | --- | --- |
| (cid:13)c CEERI, | Pilani |     |     |     |          |     |     | IC   | Design | Group |     | 215 |

| VHDL | Tutorial | : Examples |     |     |     |     |     |
| ---- | -------- | ---------- | --- | --- | --- | --- | --- |
begin
-- behavioural
|     | process(A, | B,  | CIN) |     |     |     |     |
| --- | ---------- | --- | ---- | --- | --- | --- | --- |
begin
|     | C1           | <= A and | B;   |     |     |     |     |
| --- | ------------ | -------- | ---- | --- | --- | --- | --- |
|     | C2           | <= A and | CIN; |     |     |     |     |
|     | C3           | <= B and | CIN; |     |     |     |     |
|     | end process; |          |      |     |     |     |     |
-- structural
|     | CARRY_NOR | :   | NOR3 | port map(C1, | C2, C3, | COUT); |     |
| --- | --------- | --- | ---- | ------------ | ------- | ------ | --- |
-- data-flow
|     | HALF_SUM | <=       | A xor | B;       |     |     |     |
| --- | -------- | -------- | ----- | -------- | --- | --- | --- |
|     | SUM <=   | HALF_SUM |       | xor CIN; |     |     |     |
end MIXED_ONE;
| (cid:13)c CEERI, |     | Pilani |     |     | IC Design | Group | 216 |
| ---------------- | --- | ------ | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial |     | : Examples |     |     |         |     |         |     |     |
| ---- | -------- | --- | ---------- | --- | --- | ------- | --- | ------- | --- | --- |
|      |          |     |            |     |     | Special |     | Encoder |     |     |
I4
I3 MSB
I2 LSB
I1
| entity |               | SPECIAL_ENCODER |     |        | is    |         |     |     |     |     |
| ------ | ------------- | --------------- | --- | ------ | ----- | ------- | --- | --- | --- | --- |
|        | generic(DELAY |                 |     | : TIME | :=    | 5 ns);  |     |     |     |     |
|        | port(I1,      |                 | I2, | I3, I4 | :     | in BIT; |     |     |     |     |
|        |               | MSB,            | LSB | : out  | BIT); |         |     |     |     |     |
end SPECIAL_ENCODER;
| architecture |     |     | BEHAVIOURAL |     |     | of SPECIAL_ENCODER |     |     | is  |     |
| ------------ | --- | --- | ----------- | --- | --- | ------------------ | --- | --- | --- | --- |
begin
|                  | process(I1, |        |       | I2, I3, | I4) |        |           |       |     |     |
| ---------------- | ----------- | ------ | ----- | ------- | --- | ------ | --------- | ----- | --- | --- |
|                  | variable    |        | BIT1, | BIT0    |     | : BIT; |           |       |     |     |
| (cid:13)c CEERI, |             | Pilani |       |         |     |        | IC Design | Group |     | 217 |

| VHDL | Tutorial |     | : Examples |     |     |     |     |     |     |
| ---- | -------- | --- | ---------- | --- | --- | --- | --- | --- | --- |
begin
|     | if  | ((I1   | or    | I2 or | I3     | or I4) | = ’0’) | then  |     |
| --- | --- | ------ | ----- | ----- | ------ | ------ | ------ | ----- | --- |
|     |     | assert | FALSE |       | report | "ALL   | INPUTS | ’0’"; |     |
else
|     |     | if       | I4 = | ’1’ then |            |      |         |     |     |
| --- | --- | -------- | ---- | -------- | ---------- | ---- | ------- | --- | --- |
|     |     | BIT1     | :=   | ’1’;     | BIT0       | :=   | ’1’;    |     |     |
|     |     | elsif    | I3   | = ’1’    | then       |      |         |     |     |
|     |     | BIT1     | :=   | ’1’;     | BIT0       | :=   | ’0’;    |     |     |
|     |     | elsif    | I2   | = ’1’    | then       |      |         |     |     |
|     |     | BIT1     | :=   | ’0’;     | BIT0:=’1’; |      |         |     |     |
|     |     | else     | BIT1 | :=       | ’0’;       | BIT0 | := ’0’; |     |     |
|     |     | end      | if;  |          |            |      |         |     |     |
|     | MSB | <=       | BIT1 | after    | DELAY;     |      |         |     |     |
|     | LSB | <=       | BIT0 | after    | DELAY;     |      |         |     |     |
|     | end | if;      |      |          |            |      |         |     |     |
|     | end | process; |      |          |            |      |         |     |     |
end BEHAVIOURAL;
| package          |                           | TEST_BENCH_DECL |     |     |     | is  |           |       |     |
| ---------------- | ------------------------- | --------------- | --- | --- | --- | --- | --------- | ----- | --- |
| type             | TWO_CHANNEL_TRACE_ELEMENT |                 |     |     |     |     | is record |       |     |
|                  | CH1                       | : BIT;          |     |     |     |     |           |       |     |
|                  | CH0                       | : BIT;          |     |     |     |     |           |       |     |
| (cid:13)c CEERI, |                           | Pilani          |     |     |     |     | IC Design | Group | 218 |

| VHDL Tutorial |         | : Examples |     |     |     |     |     |     |     |
| ------------- | ------- | ---------- | --- | --- | --- | --- | --- | --- | --- |
| AT            | : TIME; |            |     |     |     |     |     |     |     |
end record;
| type      | TWO_CHANNEL_TRACE_FILE |                            |     |     |       | is   |     |     |     |
| --------- | ---------------------- | -------------------------- | --- | --- | ----- | ---- | --- | --- | --- |
| file      | of                     | TWO_CHANNEL_TRACE_ELEMENT; |     |     |       |      |     |     |     |
| component |                        | SPECIAL_ENCODER_4_2        |     |     |       |      |     |     |     |
| port(I1,  |                        | I2,                        | I3, | I4  | : in  | BIT; |     |     |     |
|           | MSB,                   | LSB                        | :   | out | BIT); |      |     |     |     |
end component;
| constant                  |             | BITS_IN_VECTOR |     |     | :   | integer | :=     | 4;  |     |
| ------------------------- | ----------- | -------------- | --- | --- | --- | ------- | ------ | --- | --- |
| subtype                   | TEST_VECTOR |                |     | is  |     |         |        |     |     |
| BIT_vector(BITS_IN_VECTOR |             |                |     |     |     | - 1     | downto | 0); |     |
end TEST_BENCH_DECL;
| entity | TEST_BENCH |     |     | is  |     |     |     |     |     |
| ------ | ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
end TEST_BENCH;
use work.TEST_BENCH_DECL.all;
| (cid:13)c CEERI, | Pilani |     |     |     |     |     | IC Design | Group | 219 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial |               | : Examples    |                |     |     |               |            |              |     |     |     |
| ------------- | ------------- | ------------- | -------------- | --- | --- | ------------- | ---------- | ------------ | --- | --- | --- |
| architecture  |               |               | TEST_BENCH_1   |     |     | of            | TEST_BENCH |              |     | is  |     |
| constant      |               | NO_OF_VECTORS |                |     | :   | integer       |            | :=           | 5;  |     |     |
| type          | VECTOR_MEMORY |               |                |     | is  |               |            |              |     |     |     |
| array(1       |               | to            | NO_OF_VECTORS) |     |     |               | of         | TEST_VECTOR; |     |     |     |
| constant      |               | INPUT_VECTORS |                |     | :   | VECTOR_MEMORY |            |              |     | :=  |     |
("1010","0010","1100","0110","1111");
| constant  |       | VECTOR_PERIOD                      |                     |      | :      | TIME | :=   | 100 | ns; |     |     |
| --------- | ----- | ---------------------------------- | ------------------- | ---- | ------ | ---- | ---- | --- | --- | --- | --- |
| signal    | IN1,  |                                    | IN2,                | IN3, | IN4    | :    | BIT; |     |     |     |     |
| signal    | OUT1, |                                    | OUT2                |      | : BIT; |      |      |     |     |     |     |
| for INST1 |       | :                                  | SPECIAL_ENCODER_4_2 |      |        |      |      | use |     |     |     |
| entity    |       | work.SPECIAL_ENCODER(BEHAVIOURAL); |                     |      |        |      |      |     |     |     |     |
begin
| INST1            | :      | SPECIAL_ENCODER_4_2 |     |      |     |     |      |     |        |       |     |
| ---------------- | ------ | ------------------- | --- | ---- | --- | --- | ---- | --- | ------ | ----- | --- |
| port             | map(I1 |                     | =>  | IN1, | I2  | =>  | IN2, | I3  | =>     | IN3,  |     |
| (cid:13)c CEERI, | Pilani |                     |     |      |     |     |      | IC  | Design | Group | 220 |

| VHDL          | Tutorial : | Examples  |          |     |     |        |     |
| ------------- | ---------- | --------- | -------- | --- | --- | ------ | --- |
|               | I4 =>      | IN4, MSB  | => OUT2, | LSB | =>  | OUT1); |     |
| APPLY_VECTORS |            | : process |          |     |     |        |     |
begin
| for    | J in     | 1 to NO_OF_VECTORS   |       | loop        |     |     |     |
| ------ | -------- | -------------------- | ----- | ----------- | --- | --- | --- |
|        | IN1 <=   | INPUT_VECTORS(J)(0); |       |             |     |     |     |
|        | IN2 <=   | INPUT_VECTORS(J)(1); |       |             |     |     |     |
|        | IN3 <=   | INPUT_VECTORS(J)(2); |       |             |     |     |     |
|        | IN4 <=   | INPUT_VECTORS(J)(3); |       |             |     |     |     |
|        | wait for | VECTOR_PERIOD;       |       |             |     |     |     |
| end    | loop;    |                      |       |             |     |     |     |
| assert | FALSE    | report               | "TEST | COMPLETED"; |     |     |     |
wait;
end process;
| (cid:13)c CEERI, | Pilani |     |     |     | IC  | Design Group | 221 |
| ---------------- | ------ | --- | --- | --- | --- | ------------ | --- |

| VHDL Tutorial        | : Examples   |                              |       |     |     |
| -------------------- | ------------ | ---------------------------- | ----- | --- | --- |
| TWO_CHANNEL_RECORDER |              | : process(OUT1,              | OUT2) |     |     |
| file TRACE_OF_OUT12  |              | : TWO_CHANNEL_TRACE_FILE     |       |     |     |
| is out               | "NEW_TRACE"; |                              |       |     |     |
| variable             | SAMPLE       | : TWO_CHANNEL_TRACE_ELEMENT; |       |     |     |
begin
| SAMPLE.CH1 | :=  | OUT2; |     |     |     |
| ---------- | --- | ----- | --- | --- | --- |
| SAMPLE.CH0 | :=  | OUT1; |     |     |     |
| SAMPLE.AT  | :=  | NOW;  |     |     |     |
write(TRACE_OF_OUT12, SAMPLE);
end process;
end TEST_BENCH_1;
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 222 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |         |     |
| ------------- | ---------- | --- | ------- | --- |
|               | Modulo-3   |     | Counter |     |
Count = 0
C 0
Count = 1 Count = 1
C 2 C 1
Count = 0 Count = 0
Count = 1
| (cid:13)c CEERI, | Pilani | IC Design | Group | 223 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL Tutorial | : Examples  |     |           |     |     |               |     |           |         |     |
| ------------- | ----------- | --- | --------- | --- | --- | ------------- | --- | --------- | ------- | --- |
| Example       | : Modulo-3  |     | Counter   |     |     | (if statement |     | based     | model). |     |
| package       | COUNT_LOGIC |     |           | is  |     |               |     |           |         |     |
| type          | STATE       | is  | (COUNT_0, |     |     | COUNT_1,      |     | COUNT_2); |         |     |
end COUNT_LOGIC;
use work.COUNT_LOGIC.all;
| entity   | COUNTER_3  |      | is   |       |      |     |         |     |     |     |
| -------- | ---------- | ---- | ---- | ----- | ---- | --- | ------- | --- | --- | --- |
| port(CLK |            | : in | BIT; |       |      |     |         |     |     |     |
|          | ENABLE     | :    | in   | BIT;  |      |     |         |     |     |     |
|          | RESET_BAR  |      | :    | in    | BIT; |     |         |     |     |     |
|          | COUNT_ZERO |      |      | : out |      | BIT | := ’1’; |     |     |     |
|          | COUNT_ONE  |      | :    | out   | BIT  | :=  | ’0’;    |     |     |     |
|          | COUNT_TWO  |      | :    | out   | BIT  | :=  | ’0’);   |     |     |     |
end COUNTER_3;
| architecture |               | IF_BASED |     |     | of      | COUNTER_3 |             | is  |     |     |
| ------------ | ------------- | -------- | --- | --- | ------- | --------- | ----------- | --- | --- | --- |
| signal       | PRESENT_STATE |          |     |     | : STATE |           | := COUNT_0; |     |     |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     |     | IC Design | Group | 224 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial |     | : Examples |              |     |            |     |     |     |
| ---- | -------- | --- | ---------- | ------------ | --- | ---------- | --- | --- | --- |
|      | COUNTING |     | :          | process(CLK, |     | RESET_BAR) |     |     |     |
begin
|                  | if RESET_BAR  |                |                | = ’0’   | then        |            |           |       |     |
| ---------------- | ------------- | -------------- | -------------- | ------- | ----------- | ---------- | --------- | ----- | --- |
|                  | PRESENT_STATE |                |                |         | <= COUNT_0; |            |           |       |     |
|                  | COUNT_ZERO    |                |                | <=      | ’1’;        |            |           |       |     |
|                  | COUNT_ONE     |                |                | <= ’0’; |             |            |           |       |     |
|                  | COUNT_TWO     |                |                | <= ’0’; |             |            |           |       |     |
|                  | elsif         | (CLK           |                | = ’1’   | and         | CLK’event  |           |       |     |
|                  |               |                | and            | ENABLE  | = ’1’)      | then       |           |       |     |
|                  | if            | (PRESENT_STATE |                |         | =           | COUNT_0)   | then      |       |     |
|                  |               | PRESENT_STATE  |                |         | <=          | COUNT_1;   |           |       |     |
|                  |               | COUNT_ONE      |                | <=      | ’1’;        |            |           |       |     |
|                  |               | COUNT_ZERO     |                | <=      | ’0’;        |            |           |       |     |
|                  | elsif         |                | (PRESENT_STATE |         |             | = COUNT_1) | then      |       |     |
|                  |               | PRESENT_STATE  |                |         | <=          | COUNT_2;   |           |       |     |
|                  |               | COUNT_TWO      |                | <=      | ’1’;        |            |           |       |     |
|                  |               | COUNT_ONE      |                | <=      | ’0’;        |            |           |       |     |
| (cid:13)c CEERI, |               | Pilani         |                |         |             |            | IC Design | Group | 225 |

| VHDL Tutorial | : Examples       |            |      |     |     |
| ------------- | ---------------- | ---------- | ---- | --- | --- |
| elsif         | (PRESENT_STATE   | = COUNT_2) | then |     |     |
|               | PRESENT_STATE <= | COUNT_0;   |      |     |     |
COUNT_ZERO <= ’1’;
COUNT_TWO <= ’0’;
| end | if;               |     |     |     |     |
| --- | ----------------- | --- | --- | --- | --- |
| end | if;               |     |     |     |     |
| end | process COUNTING; |     |     |     |     |
end IF_BASED;
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 226 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples  |          |           |         |          |       |     |           |       |         |     |
| ------------- | ----------- | -------- | --------- | ------- | -------- | ----- | --- | --------- | ----- | ------- | --- |
| Example       | :           | Modulo-3 |           | Counter |          | (case |     | statement | based | model). |     |
| package       | COUNT_LOGIC |          |           | is      |          |       |     |           |       |         |     |
| type          | STATE       | is       | (COUNT_0, |         | COUNT_1, |       |     | COUNT_2); |       |         |     |
end COUNT_LOGIC;
use work.COUNT_LOGIC.all;
| entity   | COUNTER_3  |      | is   |         |     |       |      |     |     |     |     |
| -------- | ---------- | ---- | ---- | ------- | --- | ----- | ---- | --- | --- | --- | --- |
| port(CLK |            | : in | BIT; |         |     |       |      |     |     |     |     |
|          | ENABLE     | :    | in   | BIT;    |     |       |      |     |     |     |     |
|          | RESET_BAR  |      | :    | in BIT; |     |       |      |     |     |     |     |
|          | COUNT_ZERO |      | :    | out     | BIT | :=    | ’1’; |     |     |     |     |
|          | COUNT_ONE  |      | :    | out BIT | :=  | ’0’;  |      |     |     |     |     |
|          | COUNT_TWO  |      | :    | out BIT | :=  | ’0’); |      |     |     |     |     |
end COUNTER_3;
| architecture |               | CASE_BASED |     |         | of COUNTER_3 |     |          | is  |     |     |     |
| ------------ | ------------- | ---------- | --- | ------- | ------------ | --- | -------- | --- | --- | --- | --- |
| signal       | PRESENT_STATE |            |     | : STATE |              | :=  | COUNT_0; |     |     |     |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     | IC  | Design Group |     |     | 227 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | ------------ | --- | --- | --- |

| VHDL Tutorial | : Examples |              |     |            |     |     |     |
| ------------- | ---------- | ------------ | --- | ---------- | --- | --- | --- |
| COUNTING      | :          | process(CLK, |     | RESET_BAR) |     |     |     |
begin
| case             | RESET_BAR          | is      |             |           |           |       |     |
| ---------------- | ------------------ | ------- | ----------- | --------- | --------- | ----- | --- |
| when             | ’0’ =>             |         |             |           |           |       |     |
| PRESENT_STATE    |                    |         | <= COUNT_0; |           |           |       |     |
| COUNT_ZERO       |                    | <=      | ’1’;        |           |           |       |     |
| COUNT_ONE        |                    | <= ’0’; |             |           |           |       |     |
| COUNT_TWO        |                    | <= ’0’; |             |           |           |       |     |
| when             | ’1’ =>             |         |             |           |           |       |     |
| case             | (CLK               | = ’1’   | and         | CLK’event |           |       |     |
|                  | and                | ENABLE  | = ’1’)      | is        |           |       |     |
| when             | FALSE              | =>      | NULL;       |           |           |       |     |
| when             | TRUE               | =>      |             |           |           |       |     |
|                  | case PRESENT_STATE |         |             | is        |           |       |     |
|                  | when COUNT_0       |         | =>          |           |           |       |     |
|                  | PRESENT_STATE      |         | <=          | COUNT_1;  |           |       |     |
| (cid:13)c CEERI, | Pilani             |         |             |           | IC Design | Group | 228 |

| VHDL Tutorial | : Examples |     |     |     |
| ------------- | ---------- | --- | --- | --- |
COUNT_ONE <= ’1’;
COUNT_ZERO <= ’0’;
when COUNT_1 =>
PRESENT_STATE <= COUNT_2;
COUNT_TWO <= ’1’;
COUNT_ONE <= ’0’;
when COUNT_2 =>
PRESENT_STATE <= COUNT_0;
COUNT_ZERO <= ’1’;
COUNT_TWO <= ’0’;
end case;
| end | case;             |     |     |     |
| --- | ----------------- | --- | --- | --- |
| end | case;             |     |     |     |
| end | process COUNTING; |     |     |     |
end CASE_BASED;
| (cid:13)c CEERI, | Pilani | IC Design | Group | 229 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL | Tutorial : Examples |     |     |     |     |     |     |     |     |
| ---- | ------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
Example : Modulo-3 Counter (conditional signal assignment based model).
| package | COUNT_LOGIC |     |           | is  |          |     |           |     |     |
| ------- | ----------- | --- | --------- | --- | -------- | --- | --------- | --- | --- |
| type    | STATE       | is  | (COUNT_0, |     | COUNT_1, |     | COUNT_2); |     |     |
end COUNT_LOGIC;
use work.COUNT_LOGIC.all;
| entity | COUNTER_3 |     | is  |     |     |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- | --- | --- | --- | --- |
end COUNTER_3;
| architecture |               | COND_SIG |     | of         | COUNTER_3 |           | is       |        |     |
| ------------ | ------------- | -------- | --- | ---------- | --------- | --------- | -------- | ------ | --- |
| signal       | PRESENT_STATE |          |     | : STATE    |           | :=        | COUNT_0; |        |     |
| signal       | CLK,          | ENABLE,  |     | RESET_BAR  |           | :         | BIT;     |        |     |
| signal       | COUNT_ZERO,   |          |     | COUNT_ONE, |           | COUNT_TWO |          | : BIT; |     |
begin
| PRESENT_STATE    |                   |     | <=  | COUNT_0 |                |     |            |       |     |
| ---------------- | ----------------- | --- | --- | ------- | -------------- | --- | ---------- | ----- | --- |
| when             | (RESET_BAR=’0’)   |     |     | or      | (RESET_BAR=’1’ |     |            |       |     |
|                  | and PRESENT_STATE |     |     | =       | COUNT_2        |     | and        |       |     |
|                  | ENABLE=’1’        |     | and | CLK=’1’ |                | and | CLK’event) |       |     |
| (cid:13)c CEERI, | Pilani            |     |     |         |                |     | IC Design  | Group | 230 |

| VHDL | Tutorial | :   | Examples |     |     |     |     |     |     |     |     |
| ---- | -------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
else
|     | COUNT_1                |     | when |       | (RESET_BAR |     |            | = ’1’) | and        |     |     |
| --- | ---------------------- | --- | ---- | ----- | ---------- | --- | ---------- | ------ | ---------- | --- | --- |
|     | (PRESENT_STATE=COUNT_0 |     |      |       |            |     |            | and    | ENABLE=’1’ |     |     |
|     | and                    | CLK |      | = ’1’ |            | and | CLK’event) |        |            |     |     |
else
|     | COUNT_2                |     | when |       | (RESET_BAR |     |            | = ’1’) | and        |     |     |
| --- | ---------------------- | --- | ---- | ----- | ---------- | --- | ---------- | ------ | ---------- | --- | --- |
|     | (PRESENT_STATE=COUNT_1 |     |      |       |            |     |            | and    | ENABLE=’1’ |     |     |
|     | and                    | CLK |      | = ’1’ |            | and | CLK’event) |        |            |     |     |
else
PRESENT_STATE;
|                  | COUNT_ZERO |               |     | <=  | ’1’     |      | when    |      |           |       |     |
| ---------------- | ---------- | ------------- | --- | --- | ------- | ---- | ------- | ---- | --------- | ----- | --- |
|                  |            | PRESENT_STATE |     |     |         | =    | COUNT_0 | else | ’0’;      |       |     |
|                  | COUNT_ONE  |               |     | <=  | ’1’     | when |         |      |           |       |     |
|                  |            | PRESENT_STATE |     |     |         | =    | COUNT_1 | else | ’0’;      |       |     |
|                  | COUNT_TWO  |               |     | <=  | ’1’     | when |         |      |           |       |     |
|                  |            | PRESENT_STATE |     |     |         | =    | COUNT_2 | else | ’0’;      |       |     |
|                  | CLK        | <= not(CLK)   |     |     | after   |      | 25      | ns;  |           |       |     |
|                  | RESET_BAR  |               | <=  |     | ’0’,’1’ |      | after   | 20   | ns;       |       |     |
| (cid:13)c CEERI, |            | Pilani        |     |     |         |      |         |      | IC Design | Group | 231 |

| VHDL Tutorial | : Examples |       |        |     |     |     |
| ------------- | ---------- | ----- | ------ | --- | --- | --- |
| ENABLE        | <= ’0’,’1’ | after | 50 ns; |     |     |     |
end COND_SIG;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 232 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
Example : Modulo-3 Counter (selected signal assignment based model).
| package | COUNT_LOGIC  |     |           | is                 |          |     |              |     |     |
| ------- | ------------ | --- | --------- | ------------------ | -------- | --- | ------------ | --- | --- |
| type    | STATE        | is  | (COUNT_0, |                    | COUNT_1, |     | COUNT_2);    |     |     |
| type    | CONDITION    |     | is        | (CONDITION_0,      |          |     | CONDITION_1, |     |     |
|         | CONDITION_2, |     |           | CONDITION_NOTRAN); |          |     |              |     |     |
end COUNT_LOGIC;
use work.COUNT_LOGIC.all;
| entity | COUNTER_3 |     | is  |     |     |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- | --- | --- | --- | --- |
end COUNTER_3;
| architecture |               | SEL_SIG |              | of           | COUNTER_3 |           | is       |        |     |
| ------------ | ------------- | ------- | ------------ | ------------ | --------- | --------- | -------- | ------ | --- |
| signal       | PRESENT_STATE |         |              | : STATE      |           | :=        | COUNT_0; |        |     |
| signal       | SEL_CONDITION |         |              | : CONDITION; |           |           |          |        |     |
| signal       | OUTPUT        | :       | BIT_vector(2 |              |           | downto    | 0);      |        |     |
| signal       | CLK,          | ENABLE, |              | RESET_BAR    |           | :         | BIT;     |        |     |
| signal       | COUNT_ZERO,   |         |              | COUNT_ONE,   |           | COUNT_TWO |          | : BIT; |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     | IC Design | Group | 233 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL | Tutorial      |               | : Examples |                |           |            |                |       |     |
| ---- | ------------- | ------------- | ---------- | -------------- | --------- | ---------- | -------------- | ----- | --- |
|      | SEL_CONDITION |               |            | <= CONDITION_0 |           |            |                |       |     |
|      | when          | (RESET_BAR    |            | =              | ’0’) or   | (RESET_BAR |                | = ’1’ |     |
|      | and           | PRESENT_STATE |            |                | = COUNT_2 |            | and            |       |     |
|      | ENABLE        |               | = ’1’      | and            | CLK =     | ’1’        | and CLK’event) |       |     |
else
|     | CONDITION_1    |     |     | when    | (RESET_BAR |     | = ’1’) | and   |     |
| --- | -------------- | --- | --- | ------- | ---------- | --- | ------ | ----- | --- |
|     | (PRESENT_STATE |     |     | =       | COUNT_0    | and | ENABLE | = ’1’ |     |
|     | and            | CLK | =   | ’1’ and | CLK’event) |     |        |       |     |
else
|     | CONDITION_2    |     |     | when    | (RESET_BAR |     | = ’1’) | and   |     |
| --- | -------------- | --- | --- | ------- | ---------- | --- | ------ | ----- | --- |
|     | (PRESENT_STATE |     |     | =       | COUNT_1    | and | ENABLE | = ’1’ |     |
|     | and            | CLK | =   | ’1’ and | CLK’event) |     |        |       |     |
else
CONDITION_NOTRAN;
|                  | with          | SEL_CONDITION |     |                   | select |     |           |       |     |
| ---------------- | ------------- | ------------- | --- | ----------------- | ------ | --- | --------- | ----- | --- |
|                  | PRESENT_STATE |               |     | <=                |        |     |           |       |     |
|                  |               | COUNT_0       |     | when CONDITION_0, |        |     |           |       |     |
| (cid:13)c CEERI, |               | Pilani        |     |                   |        |     | IC Design | Group | 234 |

| VHDL | Tutorial : Examples |                        |                        |         |        |     |     |
| ---- | ------------------- | ---------------------- | ---------------------- | ------- | ------ | --- | --- |
|      | COUNT_1             | when                   | CONDITION_1,           |         |        |     |     |
|      | COUNT_2             | when                   | CONDITION_2,           |         |        |     |     |
|      | PRESENT_STATE       |                        | when CONDITION_NOTRAN; |         |        |     |     |
| with | SEL_CONDITION       |                        | select                 |         |        |     |     |
|      | OUTPUT              | <=                     |                        |         |        |     |     |
|      | "001"               | when CONDITION_0,      |                        |         |        |     |     |
|      | "010"               | when CONDITION_1,      |                        |         |        |     |     |
|      | "100"               | when CONDITION_2,      |                        |         |        |     |     |
|      | OUTPUT              | when CONDITION_NOTRAN; |                        |         |        |     |     |
|      | COUNT_ZERO          | <=                     | OUTPUT(0);             |         |        |     |     |
|      | COUNT_ONE           | <=                     | OUTPUT(1);             |         |        |     |     |
|      | COUNT_TWO           | <=                     | OUTPUT(2);             |         |        |     |     |
|      | CLK <=              | not(CLK)               | after                  | 25 ns;  |        |     |     |
|      | RESET_BAR           | <=                     | ’0’, ’1’               | after   | 50 ns; |     |     |
|      | ENABLE              | <= ’0’,                | ’1’ after              | 100     | ns,    |     |     |
|      |                     | ’0’                    | after                  | 300 ns; |        |     |     |
end SEL_SIG;
| (cid:13)c CEERI, | Pilani |     |     |     | IC Design | Group | 235 |
| ---------------- | ------ | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |     |     |     |     |     |     |     |     |     |
| ------------- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Example : Modulo-3 Counter (if and case statement based model).
| package | COUNT_LOGIC |     |           | is  |     |          |     |           |     |     |
| ------- | ----------- | --- | --------- | --- | --- | -------- | --- | --------- | --- | --- |
| type    | STATE       | is  | (COUNT_0, |     |     | COUNT_1, |     | COUNT_2); |     |     |
end COUNT_LOGIC;
use work.COUNT_LOGIC.all;
| entity   | COUNTER_3  |      | is   |       |      |     |         |     |     |     |
| -------- | ---------- | ---- | ---- | ----- | ---- | --- | ------- | --- | --- | --- |
| port(CLK |            | : in | BIT; |       |      |     |         |     |     |     |
|          | ENABLE     | :    | in   | BIT;  |      |     |         |     |     |     |
|          | RESET_BAR  |      | :    | in    | BIT; |     |         |     |     |     |
|          | COUNT_ZERO |      |      | : out |      | BIT | := ’1’; |     |     |     |
|          | COUNT_ONE  |      | :    | out   | BIT  | :=  | ’0’;    |     |     |     |
|          | COUNT_TWO  |      | :    | out   | BIT  | :=  | ’0’);   |     |     |     |
end COUNTER_3;
| architecture |               | CASE_IF |     |     | of      | COUNTER_3 |     | is       |     |     |
| ------------ | ------------- | ------- | --- | --- | ------- | --------- | --- | -------- | --- | --- |
| signal       | PRESENT_STATE |         |     |     | : STATE |           | :=  | COUNT_0; |     |     |
begin
| (cid:13)c CEERI, | Pilani |     |     |     |     |     |     | IC Design | Group | 236 |
| ---------------- | ------ | --- | --- | --- | --- | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Examples |              |     |            |     |     |     |
| ------------- | ---------- | ------------ | --- | ---------- | --- | --- | --- |
| COUNTING      | :          | process(CLK, |     | RESET_BAR) |     |     |     |
begin
| if RESET_BAR     |               | = ’0’   | then          |             |           |       |     |
| ---------------- | ------------- | ------- | ------------- | ----------- | --------- | ----- | --- |
| PRESENT_STATE    |               | <=      | COUNT_0;      |             |           |       |     |
| COUNT_ZERO       |               | <= ’1’; |               |             |           |       |     |
| COUNT_ONE        |               | <= ’0’; |               |             |           |       |     |
| COUNT_TWO        |               | <= ’0’; |               |             |           |       |     |
| elsif            | (CLK          | = ’1’   | and CLK’event |             |           |       |     |
|                  |               | and     | ENABLE        | = ’1’)      | then      |       |     |
| case             | PRESENT_STATE |         | is            |             |           |       |     |
|                  | when COUNT_0  |         | =>            |             |           |       |     |
|                  | PRESENT_STATE |         | <=            | COUNT_1;    |           |       |     |
|                  | COUNT_ONE     | <=      | ’1’;          |             |           |       |     |
|                  | COUNT_ZERO    |         | <= ’0’;       |             |           |       |     |
|                  | when COUNT_1  |         | =>            |             |           |       |     |
|                  | PRESENT_STATE |         |               | <= COUNT_2; |           |       |     |
|                  | COUNT_TWO     |         | <=            | ’1’;        |           |       |     |
| (cid:13)c CEERI, | Pilani        |         |               |             | IC Design | Group | 237 |

| VHDL Tutorial | : Examples |     |     |     |
| ------------- | ---------- | --- | --- | --- |
COUNT_ONE <= ’0’;
when COUNT_2 =>
PRESENT_STATE <= COUNT_0;
COUNT_ZERO <= ’1’;
COUNT_TWO <= ’0’;
| end | case;             |     |     |     |
| --- | ----------------- | --- | --- | --- |
| end | if;               |     |     |     |
| end | process COUNTING; |     |     |     |
end CASE_IF;
| (cid:13)c CEERI, | Pilani | IC Design | Group | 238 |
| ---------------- | ------ | --------- | ----- | --- |

| VHDL | Tutorial | : Annexures |     |     |     |     |     |
| ---- | -------- | ----------- | --- | --- | --- | --- | --- |
STANDARD
|     |     |     |     | Annexure-I | : Package |     |     |
| --- | --- | --- | --- | ---------- | --------- | --- | --- |
This is package STANDARD as de(cid:2)ned in the VHDL-1993 Language Reference
Manual.
| package          | standard       |           | is               |           |           |       |     |
| ---------------- | -------------- | --------- | ---------------- | --------- | --------- | ----- | --- |
|                  | type boolean   |           | is (FALSE,TRUE); |           |           |       |     |
|                  | type bit       | is (’0’,  | ’1’);            |           |           |       |     |
|                  | type character |           | is (             |           |           |       |     |
|                  | nul,           | soh, stx, | etx,             | eot, enq, | ack,      | bel,  |     |
|                  | bs,            | ht, lf,   | vt,              | ff, cr,   | so,       | si,   |     |
|                  | dle,           | dc1, dc2, | dc3,             | dc4, nak, | syn,      | etb,  |     |
|                  | can,           | em, sub,  | esc,             | fsp, gsp, | rsp,      | usp,  |     |
|                  | ’ ’,           | ’!’, ’"’, | ’#’,             | ’$’, ’%’, | ’&’,      | ’’’,  |     |
|                  | ’(’,           | ’)’, ’*’, | ’+’,             | ’,’, ’-’, | ’.’,      | ’/’,  |     |
|                  | ’0’,           | ’1’, ’2’, | ’3’,             | ’4’, ’5’, | ’6’,      | ’7’,  |     |
|                  | ’8’,           | ’9’, ’:’, | ’;’,             | ’<’, ’=’, | ’>’,      | ’?’,  |     |
|                  | ’@’,           | ’A’, ’B’, | ’C’,             | ’D’, ’E’, | ’F’,      | ’G’,  |     |
|                  | ’H’,           | ’I’, ’J’, | ’K’,             | ’L’, ’M’, | ’N’,      | ’O’,  |     |
| (cid:13)c CEERI, | Pilani         |           |                  |           | IC Design | Group | 239 |

| VHDL   | Tutorial :          | Annexures  |             |           |             |          |      |     |
| ------ | ------------------- | ---------- | ----------- | --------- | ----------- | -------- | ---- | --- |
|        | ’P’, ’Q’,           | ’R’,       |             | ’S’, ’T’, | ’U’,        | ’V’,     | ’W’, |     |
|        | ’X’, ’Y’,           | ’Z’,       |             | ’[’, ’\’, | ’]’,        | ’^’,     | ’_’, |     |
|        | ’‘’, ’a’,           | ’b’,       |             | ’c’, ’d’, | ’e’,        | ’f’,     | ’g’, |     |
|        | ’h’, ’i’,           | ’j’,       |             | ’k’, ’l’, | ’m’,        | ’n’,     | ’o’, |     |
|        | ’p’, ’q’,           | ’r’,       |             | ’s’, ’t’, | ’u’,        | ’v’,     | ’w’, |     |
|        | ’x’, ’y’,           | ’z’,       |             | ’{’, ’|’, | ’}’,        | ’~’,     | del, |     |
| --     | Plus other          | characters |             | from      | the         |          |      |     |
| --     | ISO 8859-1          | standard.  |             |           |             |          |      |     |
|        | type severity_level |            |             | is        |             |          |      |     |
| (note, | warning,            |            | error,      | failure); |             |          |      |     |
|        | type integer        |            | is range    |           |             |          |      |     |
|        |                     |            | -2147483648 | to        | 2147483647; |          |      |     |
|        | type real           | is         | range       | -1.0E308  | to          | 1.0E308; |      |     |
|        | type time           | is         | range       |           |             |          |      |     |
|        |                     |            | -2147483647 | to        | 2147483647  |          |      |     |
units
fs;
|                  | ps =   | 1000 | fs; |     |     |           |       |     |
| ---------------- | ------ | ---- | --- | --- | --- | --------- | ----- | --- |
|                  | ns =   | 1000 | ps; |     |     |           |       |     |
|                  | us =   | 1000 | ns; |     |     |           |       |     |
| (cid:13)c CEERI, | Pilani |      |     |     |     | IC Design | Group | 240 |

| VHDL Tutorial | : Annexures    |         |       |           |                  |            |       |      |     |
| ------------- | -------------- | ------- | ----- | --------- | ---------------- | ---------- | ----- | ---- | --- |
|               | ms = 1000      |         | us;   |           |                  |            |       |      |     |
|               | sec =          | 1000    | ms;   |           |                  |            |       |      |     |
|               | min =          | 60 sec; |       |           |                  |            |       |      |     |
|               | hr = 60        | min;    |       |           |                  |            |       |      |     |
| end           | units;         |         |       |           |                  |            |       |      |     |
| subtype       | delay_length   |         |       | is        | time             |            |       |      |     |
|               |                |         | range | 0         | fs to            | time’high; |       |      |     |
| impure        | function       |         | now   | return    | delay_length;    |            |       |      |     |
| subtype       | natural        |         | is    | integer   |                  |            |       |      |     |
|               |                |         | range | 0         | to integer’high; |            |       |      |     |
| subtype       | positive       |         | is    | integer   |                  |            |       |      |     |
|               |                |         | range | 1         | to integer’high; |            |       |      |     |
| type          | string         | is      | array | (positive |                  | range      |       | <>)  |     |
|               |                |         |       |           | of               | character; |       |      |     |
| type          | bit_vector     |         | is    | array     | (natural         |            | range | <>)  |     |
|               |                |         |       |           |                  |            | of    | bit; |     |
| type          | file_open_kind |         |       | is        | (                |            |       |      |     |
read_mode,
write_mode,
append_mode);
| type | file_open_status |     |     | is  | (   |     |     |     |     |
| ---- | ---------------- | --- | --- | --- | --- | --- | --- | --- | --- |
open_ok,
| (cid:13)c CEERI, | Pilani |     |     |     |     | IC  | Design | Group | 241 |
| ---------------- | ------ | --- | --- | --- | --- | --- | ------ | ----- | --- |

| VHDL Tutorial | : Annexures |     |     |     |     |
| ------------- | ----------- | --- | --- | --- | --- |
status_error,
name_error,
mode_error);
| attribute | foreign | : string; |     |     |     |
| --------- | ------- | --------- | --- | --- | --- |
end standard;
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 242 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial |        | : Annexures |         |          |         |             |     |     |           |     |        |     |
| ------------- | ------ | ----------- | ------- | -------- | ------- | ----------- | --- | --- | --------- | --- | ------ | --- |
|               |        |             |         |          |         | Annexure-II |     |     | : Package |     | TEXTIO |     |
| package       | TEXTIO |             | is      |          |         |             |     |     |           |     |        |     |
| type LINE     |        | is          | access  |          | string; |             |     |     |           |     |        |     |
| type TEXT     |        | is          | file    | of       | string; |             |     |     |           |     |        |     |
| type SIDE     |        | is          | (right, |          | left);  |             |     |     |           |     |        |     |
| subtype       | WIDTH  |             | is      | natural; |         |             |     |     |           |     |        |     |
| -- changed    |        | for         | VHDL93  |          |         | syntax:     |     |     |           |     |        |     |
| file input    |        | :           | TEXT    | open     |         | read_mode   |     | is  |           |     |        |     |
"STD_INPUT";
| file output |     |     | : TEXT |     | open | write_mode |     |     | is  |     |     |     |
| ----------- | --- | --- | ------ | --- | ---- | ---------- | --- | --- | --- | --- | --- | --- |
"STD_OUTPUT";
| -- changed       |        | for           | VHDL93    |     |     | (and  | now    | a built-in): |        |        |     |     |
| ---------------- | ------ | ------------- | --------- | --- | --- | ----- | ------ | ------------ | ------ | ------ | --- | --- |
| procedure        |        | READLINE(file |           |     |     | f:    | TEXT;  | L:           | out    | LINE); |     |     |
| procedure        |        | READ(L:inout  |           |     |     | LINE; | VALUE: |              | out    | bit;   |     |     |
| GOOD             | :      | out           | BOOLEAN); |     |     |       |        |              |        |        |     |     |
| procedure        |        | READ(L:inout  |           |     |     | LINE; | VALUE: |              | out    | bit);  |     |     |
| (cid:13)c CEERI, | Pilani |               |           |     |     |       |        | IC           | Design | Group  |     | 243 |

| VHDL Tutorial    | : Annexures      |      |       |       |                 |       |     |
| ---------------- | ---------------- | ---- | ----- | ----- | --------------- | ----- | --- |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out bit_vector;  |      |       | GOOD  | : out BOOLEAN); |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out bit_vector); |      |       |       |                 |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out BOOLEAN;     |      | GOOD  | :     | out BOOLEAN);   |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out BOOLEAN);    |      |       |       |                 |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out character;   |      |       | GOOD  | : out BOOLEAN); |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out character);  |      |       |       |                 |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out integer;     |      | GOOD  | :     | out BOOLEAN);   |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out integer);    |      |       |       |                 |       |     |
| procedure        | READ(L:inout     |      | LINE; |       |                 |       |     |
| VALUE:           | out real;        | GOOD |       | : out | BOOLEAN);       |       |     |
| (cid:13)c CEERI, | Pilani           |      |       |       | IC Design       | Group | 244 |

| VHDL Tutorial    |        | : Annexures    |              |      |        |        |               |           |       |     |
| ---------------- | ------ | -------------- | ------------ | ---- | ------ | ------ | ------------- | --------- | ----- | --- |
| procedure        |        | READ(L:inout   |              |      |        | LINE;  |               |           |       |     |
| VALUE:           |        | out            | real);       |      |        |        |               |           |       |     |
| procedure        |        | READ(L:inout   |              |      |        | LINE;  |               |           |       |     |
| VALUE:           |        | out            | string;      |      | GOOD   |        | : out         | BOOLEAN); |       |     |
| procedure        |        | READ(L:inout   |              |      |        | LINE;  |               |           |       |     |
| VALUE:           |        | out            | string);     |      |        |        |               |           |       |     |
| procedure        |        | READ(L:inout   |              |      |        | LINE;  |               |           |       |     |
| VALUE:           |        | out            | time;        |      | GOOD   | :      | out BOOLEAN); |           |       |     |
| procedure        |        | READ(L:inout   |              |      |        | LINE;  |               |           |       |     |
| VALUE:           |        | out            | time);       |      |        |        |               |           |       |     |
| -- changed       |        | for            | VHDL93       |      | syntax |        |               |           |       |     |
| -- (and          | now    |                | a built-in): |      |        |        |               |           |       |     |
| procedure        |        | WRITELINE(file |              |      |        | f      | : TEXT;       |           |       |     |
| L :              | inout  |                | LINE);       |      |        |        |               |           |       |     |
| procedure        |        | WRITE(L        |              | :    | inout  |        | LINE;         |           |       |     |
| VALUE            | :      | in             | bit;         |      |        |        |               |           |       |     |
| JUSTIFIED:       |        |                | in           | SIDE | :=     | right; |               |           |       |     |
| FIELD:           |        | in             | WIDTH        | :=   | 0);    |        |               |           |       |     |
| (cid:13)c CEERI, | Pilani |                |              |      |        |        |               | IC Design | Group | 245 |

| VHDL Tutorial    | : Annexures |             |             |           |       |     |
| ---------------- | ----------- | ----------- | ----------- | --------- | ----- | --- |
| procedure        | WRITE(L     | :           | inout LINE; |           |       |     |
| VALUE            | : in        | bit_vector; |             |           |       |     |
| JUSTIFIED:       |             | in SIDE     | := right;   |           |       |     |
| FIELD:           | in          | WIDTH :=    | 0);         |           |       |     |
| procedure        | WRITE(L     | :           | inout LINE; |           |       |     |
| VALUE            | : in        | BOOLEAN;    |             |           |       |     |
| JUSTIFIED:       |             | in SIDE     | := right;   |           |       |     |
| FIELD:           | in          | WIDTH :=    | 0);         |           |       |     |
| procedure        | WRITE(L     | :           | inout LINE; |           |       |     |
| VALUE            | : in        | character;  |             |           |       |     |
| JUSTIFIED:       |             | in SIDE     | := right;   |           |       |     |
| FIELD:           | in          | WIDTH :=    | 0);         |           |       |     |
| procedure        | WRITE(L     | :           | inout LINE; |           |       |     |
| VALUE            | : in        | integer;    |             |           |       |     |
| JUSTIFIED:       |             | in SIDE     | := right;   |           |       |     |
| FIELD:           | in          | WIDTH :=    | 0);         |           |       |     |
| procedure        | WRITE(L     | :           | inout LINE; |           |       |     |
| VALUE            | : in        | real;       |             |           |       |     |
| JUSTIFIED:       |             | in SIDE     | := right;   |           |       |     |
| (cid:13)c CEERI, | Pilani      |             |             | IC Design | Group | 246 |

| VHDL Tutorial | : Annexures |          |             |     |     |     |
| ------------- | ----------- | -------- | ----------- | --- | --- | --- |
| FIELD:        | in          | WIDTH := | 0;          |     |     |     |
| DIGITS:       | in          | NATURAL  | := 0);      |     |     |     |
| procedure     | WRITE(L     | :        | inout LINE; |     |     |     |
| VALUE         | : in        | string;  |             |     |     |     |
| JUSTIFIED:    |             | in SIDE  | := right;   |     |     |     |
| FIELD:        | in          | WIDTH := | 0);         |     |     |     |
| procedure     | WRITE(L     | :        | inout LINE; |     |     |     |
| VALUE         | : in        | time;    |             |     |     |     |
| JUSTIFIED:    |             | in SIDE  | := right;   |     |     |     |
| FIELD:        | in          | WIDTH := | 0;          |     |     |     |
| UNIT:         | in          | TIME :=  | ns);        |     |     |     |
end;
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 247 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Annexures |     |     |     |     |     |
| ------------- | ----------- | --- | --- | --- | --- | --- |
STD LOGIC 1164
|                        |                  |           | Annexure-III            | : Package |       |     |
| ---------------------- | ---------------- | --------- | ----------------------- | --------- | ----- | --- |
| PACKAGE                | std_logic_1164   |           | IS                      |           |       |     |
| -- logic               | state            | system    | (unresolved)            |           |       |     |
| TYPE std_ulogic        |                  | IS        | (                       |           |       |     |
| ’U’,                   | -- Uninitialized |           |                         |           |       |     |
| ’X’,                   | -- Forcing       |           | Unknown                 |           |       |     |
| ’0’,                   | -- Forcing       |           | 0                       |           |       |     |
| ’1’,                   | -- Forcing       |           | 1                       |           |       |     |
| ’Z’,                   | -- High          | Impedance |                         |           |       |     |
| ’W’,                   | -- Weak          |           | Unknown                 |           |       |     |
| ’L’,                   | -- Weak          |           | 0                       |           |       |     |
| ’H’,                   | -- Weak          |           | 1                       |           |       |     |
| ’-’                    | -- Don’t         | care);    |                         |           |       |     |
| TYPE std_ulogic_vector |                  |           | IS ARRAY                |           |       |     |
| (NATURAL               | RANGE            | <>)       | OF std_ulogic;          |           |       |     |
| -- resolution          |                  | function  |                         |           |       |     |
| FUNCTION               | resolved         |           | (s : std_ulogic_vector) |           |       |     |
| RETURN                 | std_ulogic;      |           |                         |           |       |     |
| (cid:13)c CEERI,       | Pilani           |           |                         | IC Design | Group | 248 |

| VHDL Tutorial         |             | : Annexures |         |               |             |                       |             |       |     |
| --------------------- | ----------- | ----------- | ------- | ------------- | ----------- | --------------------- | ----------- | ----- | --- |
| SUBTYPE               | std_logic   |             |         | IS            | resolved    |                       | std_ulogic; |       |     |
| TYPE std_logic_vector |             |             |         |               | IS          | ARRAY                 |             |       |     |
| (NATURAL              |             | RANGE       |         | <>)           | OF          | std_logic;            |             |       |     |
| -- common             |             | subtypes    |         |               |             |                       |             |       |     |
| SUBTYPE               | X01         |             | IS      | resolved      |             | std_ulogic            |             |       |     |
| RANGE                 | ’X’         |             | TO      | ’1’;          | --          | (’X’,’0’,’1’)         |             |       |     |
| SUBTYPE               | X01Z        |             | IS      | resolved      |             | std_ulogic            |             |       |     |
| RANGE                 | ’X’         |             | TO      | ’Z’;          | --          | (’X’,’0’,’1’,’Z’)     |             |       |     |
| SUBTYPE               | UX01        |             | IS      | resolved      |             | std_ulogic            |             |       |     |
| RANGE                 | ’U’         |             | TO      | ’1’;          | --          | (’U’,’X’,’0’,’1’)     |             |       |     |
| SUBTYPE               | UX01Z       |             | IS      | resolved      |             | std_ulogic            |             |       |     |
| RANGE                 | ’U’         |             | TO      | ’Z’;          | --          | (’U’,’X’,’0’,’1’,’Z’) |             |       |     |
| -- overloaded         |             |             | logical |               | operators   |                       |             |       |     |
| FUNCTION              |             | "and"       |         | (l :          | std_ulogic; |                       |             |       |     |
| r :                   | std_ulogic) |             |         | RETURN        |             | UX01;                 |             |       |     |
| FUNCTION              |             | "nand"      |         | (l :          | std_ulogic; |                       |             |       |     |
| r :                   | std_ulogic) |             |         | RETURN        |             | UX01;                 |             |       |     |
| FUNCTION              |             | "or"        | (l      | : std_ulogic; |             |                       |             |       |     |
| (cid:13)c CEERI,      | Pilani      |             |         |               |             |                       | IC Design   | Group | 249 |

| VHDL Tutorial    | : Annexures        |            |                        |           |       |     |
| ---------------- | ------------------ | ---------- | ---------------------- | --------- | ----- | --- |
| r :              | std_ulogic)        | RETURN     | UX01;                  |           |       |     |
| FUNCTION         | "nor"              | (l :       | std_ulogic;            |           |       |     |
| r :              | std_ulogic)        | RETURN     | UX01;                  |           |       |     |
| FUNCTION         | "xor"              | (l :       | std_ulogic;            |           |       |     |
| r :              | std_ulogic)        | RETURN     | UX01;                  |           |       |     |
| function         | "xnor"             | (l         | : std_ulogic;          |           |       |     |
| r :              | std_ulogic)        | RETURN     | ux01;                  |           |       |     |
| FUNCTION         | "not"              | (l :       | std_ulogic)            |           |       |     |
|                  |                    | RETURN     | UX01;                  |           |       |     |
| -- vectorized    |                    | overloaded | logical                | operators |       |     |
| FUNCTION         | "and"              | (l,        | r : std_logic_vector)  |           |       |     |
| RETURN           | std_logic_vector;  |            |                        |           |       |     |
| FUNCTION         | "and"              | (l,        | r : std_ulogic_vector) |           |       |     |
| RETURN           | std_ulogic_vector; |            |                        |           |       |     |
| FUNCTION         | "nand"             | (l,        | r : std_logic_vector)  |           |       |     |
| RETURN           | std_logic_vector;  |            |                        |           |       |     |
| FUNCTION         | "nand"             | (l,        | r : std_ulogic_vector) |           |       |     |
| RETURN           | std_ulogic_vector; |            |                        |           |       |     |
| FUNCTION         | "or"               | (l, r      | : std_logic_vector)    |           |       |     |
| (cid:13)c CEERI, | Pilani             |            |                        | IC Design | Group | 250 |

| VHDL Tutorial    | : Annexures        |       |                        |           |       |     |
| ---------------- | ------------------ | ----- | ---------------------- | --------- | ----- | --- |
| RETURN           | std_logic_vector;  |       |                        |           |       |     |
| FUNCTION         | "or"               | (l, r | : std_ulogic_vector)   |           |       |     |
| RETURN           | std_ulogic_vector; |       |                        |           |       |     |
| FUNCTION         | "nor"              | (l,   | r : std_logic_vector)  |           |       |     |
| RETURN           | std_logic_vector;  |       |                        |           |       |     |
| FUNCTION         | "nor"              | (l,   | r : std_ulogic_vector) |           |       |     |
| RETURN           | std_ulogic_vector; |       |                        |           |       |     |
| FUNCTION         | "xor"              | (l,   | r : std_logic_vector)  |           |       |     |
| RETURN           | std_logic_vector;  |       |                        |           |       |     |
| FUNCTION         | "xor"              | (l,   | r : std_ulogic_vector) |           |       |     |
| RETURN           | std_ulogic_vector; |       |                        |           |       |     |
| function         | "xnor"             | (l,   | r : std_logic_vector)  |           |       |     |
| RETURN           | std_logic_vector;  |       |                        |           |       |     |
| function         | "xnor"             | (l,   | r : std_ulogic_vector) |           |       |     |
| RETURN           | std_ulogic_vector; |       |                        |           |       |     |
| FUNCTION         | "not"              | (l :  | std_logic_vector)      |           |       |     |
| RETURN           | std_logic_vector;  |       |                        |           |       |     |
| FUNCTION         | "not"              | (l :  | std_ulogic_vector)     |           |       |     |
| (cid:13)c CEERI, | Pilani             |       |                        | IC Design | Group | 251 |

| VHDL Tutorial    | : Annexures        |           |             |                    |       |     |
| ---------------- | ------------------ | --------- | ----------- | ------------------ | ----- | --- |
| RETURN           | std_ulogic_vector; |           |             |                    |       |     |
| -- conversion    |                    | functions |             |                    |       |     |
| FUNCTION         | To_bit             | (s :      | std_ulogic; |                    |       |     |
| xmap             | : BIT :=           | ’0’)      | RETURN      | BIT;               |       |     |
| FUNCTION         | To_bitvector       |           | (s :        | std_logic_vector;  |       |     |
| xmap             | : BIT :=           | ’0’)      | RETURN      | BIT_vector;        |       |     |
| FUNCTION         | To_bitvector       |           | (s :        | std_ulogic_vector; |       |     |
| xmap             | : BIT :=           | ’0’)      | RETURN      | BIT_vector;        |       |     |
| FUNCTION         | To_StdULogic       |           | (b :        | BIT)               |       |     |
| RETURN           | std_ulogic;        |           |             |                    |       |     |
| FUNCTION         | To_StdLogicVector  |           |             | (b : BIT_vector)   |       |     |
| RETURN           | std_logic_vector;  |           |             |                    |       |     |
| FUNCTION         | To_StdLogicVector  |           |             |                    |       |     |
| (s :             | std_ulogic_vector) |           |             |                    |       |     |
| RETURN           | std_logic_vector;  |           |             |                    |       |     |
| FUNCTION         | To_StdULogicVector |           |             | (b : BIT_vector)   |       |     |
| RETURN           | std_ulogic_vector; |           |             |                    |       |     |
| FUNCTION         | To_StdULogicVector |           |             |                    |       |     |
| (s :             | std_logic_vector)  |           |             |                    |       |     |
| RETURN           | std_ulogic_vector; |           |             |                    |       |     |
| (cid:13)c CEERI, | Pilani             |           |             | IC Design          | Group | 252 |

| VHDL Tutorial    | : Annexures        |      |                      |            |       |     |
| ---------------- | ------------------ | ---- | -------------------- | ---------- | ----- | --- |
| -- strength      | strippers          |      | and type             | convertors |       |     |
| FUNCTION         | To_X01             | (s : | std_logic_vector)    |            |       |     |
| RETURN           | std_logic_vector;  |      |                      |            |       |     |
| FUNCTION         | To_X01             | (s : | std_ulogic_vector)   |            |       |     |
| RETURN           | std_ulogic_vector; |      |                      |            |       |     |
| FUNCTION         | To_X01             | (s : | std_ulogic)          |            |       |     |
| RETURN           | X01;               |      |                      |            |       |     |
| FUNCTION         | To_X01             | (b : | BIT_vector)          |            |       |     |
| RETURN           | std_logic_vector;  |      |                      |            |       |     |
| FUNCTION         | To_X01             | (b : | BIT_vector)          |            |       |     |
| RETURN           | std_ulogic_vector; |      |                      |            |       |     |
| FUNCTION         | To_X01             | (b : | BIT)                 |            |       |     |
| RETURN           | X01;               |      |                      |            |       |     |
| FUNCTION         | To_X01Z            | (s   | : std_logic_vector)  |            |       |     |
| RETURN           | std_logic_vector;  |      |                      |            |       |     |
| FUNCTION         | To_X01Z            | (s   | : std_ulogic_vector) |            |       |     |
| RETURN           | std_ulogic_vector; |      |                      |            |       |     |
| FUNCTION         | To_X01Z            | (s   | : std_ulogic)        |            |       |     |
| RETURN           | X01Z;              |      |                      |            |       |     |
| FUNCTION         | To_X01Z            | (b   | : BIT_vector)        |            |       |     |
| (cid:13)c CEERI, | Pilani             |      |                      | IC Design  | Group | 253 |

| VHDL Tutorial    | : Annexures        |                         |                 |       |     |
| ---------------- | ------------------ | ----------------------- | --------------- | ----- | --- |
| RETURN           | std_logic_vector;  |                         |                 |       |     |
| FUNCTION         | To_X01Z            | (b : BIT_vector)        |                 |       |     |
| RETURN           | std_ulogic_vector; |                         |                 |       |     |
| FUNCTION         | To_X01Z            | (b : BIT)               |                 |       |     |
| RETURN           | X01Z;              |                         |                 |       |     |
| FUNCTION         | To_UX01            | (s : std_logic_vector)  |                 |       |     |
| RETURN           | std_logic_vector;  |                         |                 |       |     |
| FUNCTION         | To_UX01            | (s : std_ulogic_vector) |                 |       |     |
| RETURN           | std_ulogic_vector; |                         |                 |       |     |
| FUNCTION         | To_UX01            | (s : std_ulogic)        |                 |       |     |
| RETURN           | UX01;              |                         |                 |       |     |
| FUNCTION         | To_UX01            | (b : BIT_vector)        |                 |       |     |
| RETURN           | std_logic_vector;  |                         |                 |       |     |
| FUNCTION         | To_UX01            | (b : BIT_vector)        |                 |       |     |
| RETURN           | std_ulogic_vector; |                         |                 |       |     |
| FUNCTION         | To_UX01            | (b : BIT)               |                 |       |     |
| RETURN           | UX01;              |                         |                 |       |     |
| -- edge          | detection          |                         |                 |       |     |
| FUNCTION         | rising_edge        | (SIGNAL                 | s : std_ulogic) |       |     |
| RETURN           | BOOLEAN;           |                         |                 |       |     |
| (cid:13)c CEERI, | Pilani             |                         | IC Design       | Group | 254 |

| VHDL Tutorial | : Annexures  |                      |                 |     |     |
| ------------- | ------------ | -------------------- | --------------- | --- | --- |
| FUNCTION      | falling_edge | (SIGNAL              | s : std_ulogic) |     |     |
| RETURN        | BOOLEAN;     |                      |                 |     |     |
| -- object     | contains     | an unknown           |                 |     |     |
| FUNCTION      | Is_X (s      | : std_ulogic_vector) |                 |     |     |
| RETURN        | BOOLEAN;     |                      |                 |     |     |
| FUNCTION      | Is_X (s      | : std_logic_vector)  |                 |     |     |
| RETURN        | BOOLEAN;     |                      |                 |     |     |
| FUNCTION      | Is_X (s      | : std_ulogic)        |                 |     |     |
| RETURN        | BOOLEAN;     |                      |                 |     |     |
END std_logic_1164;
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 255 |
| ---------------- | ------ | --- | --------- | ----- | --- |

| VHDL Tutorial | : Books | List |      |         |       |     |
| ------------- | ------- | ---- | ---- | ------- | ----- | --- |
|               |         |      | VHDL | Related | Books |     |
1. IEEE Standard 1076-2001, VHDL Langauge Reference Manual, IEEE
| Press, | 2001. |     |     |     |     |     |
| ------ | ----- | --- | --- | --- | --- | --- |
2. R. Lipsett, C. Schaefer and C. Ussery, VHDL : Hardware Description and
| Design, | Kluwer, | 1989. | (Out | of Print) |     |     |
| ------- | ------- | ----- | ---- | --------- | --- | --- |
3. J. Bhasker, A VHDL Primer, Third Edition, Prentice-Hall, 1999. (Cheap
Edition)
4. J. Bhasker, A VHDL Synthesis Primer, Second Edition, Star Galaxy, 1998.
| (Cheap           | Edition) |     |     |           |       |     |
| ---------------- | -------- | --- | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani   |     |     | IC Design | Group | 256 |

| VHDL Tutorial | : Books | List |     |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- | --- |
5. S. Sjoholm and L. Lindh, VHDL for Designers, Prentice-Hall, 1997.
6. P. J. Ashenden, The Designer’s Guide to VHDL, Second Edition, Morgan
| Kaufmann, |     | 2002. | (Cheap | Edition) |     |     |
| --------- | --- | ----- | ------ | -------- | --- | --- |
7. P. J. Ashenden, The Student’s Guide to VHDL, Morgan Kaufmann, 1998.
8. J. Armstrong and F. G. Gray, VHDL Design Representation and Synthesis,
| Second |     | Edition, | Prentice-Hall, | 2000. |     |     |
| ------ | --- | -------- | -------------- | ----- | --- | --- |
9. D. Naylor and S. Jones, VHDL : A Logic Synthesis Approach, Chapman &
| Hall,            | 1997.  |     |     |           |       |     |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 257 |

| VHDL Tutorial | : Books | List |     |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- | --- |
10. S. Yalamanchili, Introductory VHDL : From Simulation to Synthesis, Prentice-
| Hall, | 2001. | (Cheap | Edition) |     |     |     |
| ----- | ----- | ------ | -------- | --- | --- | --- |
11. J. Pick, VHDL : Techniques, Experiments and Caveats, McGraw-Hill, 1996.
| (Cheap | Edition) |     |     |     |     |     |
| ------ | -------- | --- | --- | --- | --- | --- |
12. B. Cohen, VHDL Coding Styles and Methodologies, Second Edition, Kluwer,
1999.
13. B. Cohen, VHDL Answers to Frequently Asked Questions, Second Edition,
| Kluwer, | 1998. |     |     |     |     |     |
| ------- | ----- | --- | --- | --- | --- | --- |
14. D. E. Ott and T. J. Wilderotter, A Designer’s Guide to VHDL Synthesis,
| Kluwer,          | 1994.  |     |     |           |       |     |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 258 |

| VHDL | Tutorial | : Books | List |     |     |     |     |     |     |
| ---- | -------- | ------- | ---- | --- | --- | --- | --- | --- | --- |
15. C. H. Roth, Digital System Design with VHDL, PWS/Brookscole, 1998.
|     | (Cheap |     | Edition) |     |     |     |     |     |     |
| --- | ------ | --- | -------- | --- | --- | --- | --- | --- | --- |
16. Z. Navabi, VHDL : Analysis and Modeling of Digital Systems, Second Edi-
|     | tion,       | McGraw-Hill, |         | 1998. | (Cheap | Edition) |                |       |     |
| --- | ----------- | ------------ | ------- | ----- | ------ | -------- | -------------- | ----- | --- |
| 17. | J. Bhasker, |              | A Guide | to    | VHDL   | Syntax,  | Prentice-Hall, | 1995. |     |
18. D. J. Smith, HDL Chip Design : A Practical Guide, Doone Publisher, 1997.
19. K. C. Chang, Digital Design and Modeling with VHDL and Synthesis,
|                  | IEEE-CS |        | Press, | 1999. |     |           |       |     |     |
| ---------------- | ------- | ------ | ------ | ----- | --- | --------- | ----- | --- | --- |
| (cid:13)c CEERI, |         | Pilani |        |       |     | IC Design | Group |     | 259 |

| VHDL Tutorial | : Books | List |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- |
20. P. Eles, K. Kuchcinski and Z. Peng, System Synthesis with VHDL, Kluwer,
1998.
21. L. Baker, VHDL Programming with Advanced Topics, John Wiley, 1993.
22. A. Dewey, Analysis and Design of Digital Systems with VHDL, PWS/Brookscole,
1997.
23. Z. Salcic, VHDL and FPLDs in Digital System Design, Prototyping and
| Customization, |     | Kluwer, | 1998. |     |     |
| -------------- | --- | ------- | ----- | --- | --- |
24. F. A. Scarpino, VHDL and AHDL Digital System Implementation, Prentice-
| Hall,            | 1998.  |     |           |       |     |
| ---------------- | ------ | --- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani |     | IC Design | Group | 260 |

| VHDL Tutorial | : Books | List |     |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- | --- |
25. B. Cohen, Component Design by Example : A Step-by-Step Process Us-
| ing | VHDL | with UART | as Vehicle, | 2001. |     |     |
| --- | ---- | --------- | ----------- | ----- | --- | --- |
26. D. L. Perry, VHDL, Third Edition, McGraw-Hill, 1998. (Cheap Edition)
27. W. F. Lee, Guide to Synthesizable VHDL Coding and Logic Synthesis, AP,
199x.
28. M. S. B. Romdhane, V. K. Madisetti and J. W. Hines, Quick-Turnaround
ASIC Design in VHDL Core-Based Behavioral Synthesis, Kluwer, 1996.
| 29. D.           | Hunter, | Introduction | to VHDL, | Kluwer,   | 1997. |     |
| ---------------- | ------- | ------------ | -------- | --------- | ----- | --- |
| (cid:13)c CEERI, | Pilani  |              |          | IC Design | Group | 261 |

| VHDL Tutorial | : Books | List |     |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- | --- |
30. S. Brown and Z. Vranesic, Fundamentals of Digital Logic with VHDL,
| McGraw-Hill, |     | 199x. |     |     |     |     |
| ------------ | --- | ----- | --- | --- | --- | --- |
31. Y-C. Hsu, F. Tsai, J. T. Liu and E. S. Lin, VHDL Modeling for Digital Design
| Synthesis, |     | Kluwer, | 1995. |     |     |     |
| ---------- | --- | ------- | ----- | --- | --- | --- |
32. J. Armstrong and F. G. Gray, Structured Logic Design with VHDL, Prentice-
| Hall, | 1993. | (Out of | Print) |     |     |     |
| ----- | ----- | ------- | ------ | --- | --- | --- |
33. J. M. Berge, A. Fonkua, S. Maginot and J. Roulliard, VHDL Designer’s
| Reference, |     | Kluwer, | 1992. | (Out of | Print) |     |
| ---------- | --- | ------- | ----- | ------- | ------ | --- |
34. D. R. Coelho, The VHDL Handbook, Kluwer, 1989. (Out of Print)
| (cid:13)c CEERI, | Pilani |     |     | IC Design | Group | 262 |
| ---------------- | ------ | --- | --- | --------- | ----- | --- |

| VHDL Tutorial | : Books | List |     |     |     |     |
| ------------- | ------- | ---- | --- | --- | --- | --- |
35. S. S. Leung and M. A. Shanblatt, ASIC System Design with VHDL : A
| Paradigm,        |        | Kluwer, | 1989. | (Out of | Print)       |     |
| ---------------- | ------ | ------- | ----- | ------- | ------------ | --- |
| (cid:13)c CEERI, | Pilani |         |       | IC      | Design Group | 263 |