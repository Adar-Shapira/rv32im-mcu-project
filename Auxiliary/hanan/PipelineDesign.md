Pipeline Design
Computer Architecture
Dr. Guy Tel-Zur
|     | 5/2024 :ןורחא ןוכדיע |     |
| --- | -------------------- | --- |

תגצמה תורטמ
Pipeline -ה גשומ תנבה סוסיב
םיעוציבה לע םיעיפשמה םידדמ -
:םייזכרמ םיחנומ -
ןונכתה תונורקע ,ויקוח ,Pipeline-ה תוגרד
המגוד ןתמ -

This presentation is based on:
MIT Open course ware "Computation Structures"
●
by Dr. Christopher J. Terman.
References:
●
Chris Terman. 6.004 Computation
– MIT Open course ware
Structures. Spring 2017. Massachusetts
Institute of Technology: MIT
MIT6.004 2017
OpenCourseWare, https://ocw.mit.edu.
License: Creative Commons BY-NC-SA.
– Slides 13-15 :
Slides by Prof. Shmuel Wimer Technion/BIU
In particular we will discuss material from:
https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-004-computatio
n-structures-spring-2017/c7/c7s1/#1
See 7.2.2, 7.2.3, 7.2.4 @ MIT open course ware site

PD = Prop agation delay, Period

Harvard ןיבל MIT ןיב וגא יקחשמ

BGU
םיינשה ןיבמ יטיאה יפל

לכ אצוי טירפ
תוקד 60

ataD
tupnI
X
i
X
i+1
X
i+2

fixed Pipeline
A
X C
B
Y
This is mainly a 4-pipeline with a twist of 3-pipeline to allow
mixing A(X ) and Y at the input of B.
i+1 i

|     |  לש יתטיש ןונכת |     |
| --- | --------------- | --- |
Pipeline
  :הרדגה •
K - Pipeline
בושמ אלל יגול לגעמ –
–
םירגואו םייפוריצ םיביכר ללוכ
| םירגוא  |  קוידב ללוכ האיציל הסינכמ לולסמ לכ | –   |
| ------- | ---------------------------------- | --- |
K
16

םוחתל

Ref: https://web.mit.edu/6.111/www/f2016/handouts/L09.pdf

דבלב םיפורצ תכרעמ
1 וק
2+1 םיווק
3+2+1 םיוק
ןיא ,ש"נ2 תחא לכ ,תוגרד 3
ש"נ2 תחא לכ ,תוגרד 2
רופיש

םישרתה ותוא

7.2.3 קלחב ןורחא ףקש

BGU

| Load #1 | Wash #1 | Dryer1 - load #1 |
| ------- | ------- | ---------------- |
sdaoL
Dryer2-load #2
| Load #2 | Wash #2 |     |
| ------- | ------- | --- |
Wash #2 Dryer1 - load #3
Load #3
Dryer2 - load #4
Wash #4
Load #4

רדת קלחמ
Click for animation
Credit: https://en.wikipedia.org/wiki/Frequency_divider

L = ךורא יכה ןמזה לופכ םילוגיעה תומכ =
L = ש ”נ 5 לופכ ביתנ לכב )םירטסיגר( םילוגיע השימח

T=Throughput

|         |     |     |
| ------- | --- | --- |
| וז תגצמ | ןאכ | דע  |