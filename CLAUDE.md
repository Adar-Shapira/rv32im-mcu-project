# חוקי עבודה — פרויקט RV32IM MCU

עבודה הנדסית, מדורגת, ומבוססת מקורות בלבד.

**העיקרון העליון:** אסור להמציא ארכיטקטורה, מודולים, קבצים, ממשקים או מימושים רק משום שהם
נראים הגיוניים. כל דבר שמוצע לממש נבדק קודם מול החומרים הקיימים בפרויקט. עוצרים בכל שלב
ומוודאים שהכיוון מבוסס על Reference אמיתי לפני שממשיכים.

**עדיף לעצור ולומר "לא מצאתי Reference שמוכיח את זה" מאשר להמציא פתרון שנראה סביר.**

---

## בדיקת מקורות לפני כתיבת קוד

לפני יצירה, שינוי או השלמה של קובץ VHDL, Testbench, Quartus configuration, ModelSim script,
firmware, memory map, peripheral או כל רכיב אחר — להציג:

1. מה בדיוק עומדים לממש.
2. למה הרכיב נדרש לפי הגדרת הפרויקט.
3. איזה Reference קיים שימש להבנת המימוש.
4. הנתיב המדויק של אותו Reference בפרויקט (לדוגמה `Auxiliary/Lab 5/DUT/RV32IM_sc/...`,
   `Auxiliary/Lab 5/DUT/RV32IM_pipeline/...`, `Auxiliary/Benchmark Apps/...`,
   `Auxiliary/Final Project 2026 definition.pdf`).
5. אילו חלקים אפשר לקחת או להתאים ישירות מה-Reference.
6. אילו חלקים אינם קיימים ב-Reference ולכן דורשים פיתוח חדש.
7. כל הנחה שאינה כתובה במפורש בחומר — מסומנת במפורש כ-**Assumption**, לא כעובדה.

## סדר עדיפויות למקורות

1. הגדרת הפרויקט הרשמית.
2. הקוד והחומרים שחנן סיפק עבור המעבדות הרלוונטיות.
3. מעבדות קודמות ב-`Auxiliary`.
4. Benchmark Apps, Testbenches, `io_map.s`, קבצי memory initialization, Quartus projects,
   SignalTap files ושאר קבצים שסופקו בקורס.
5. רק לאחר מיצוי כל אלה — ידע כללי על RISC-V / Digital Design / FPGA, **ותוך אמירה מפורשת
   שזה אינו מגיע מחומר שסופק בקורס.**

## Auxiliary הוא Reference בלבד

ספריית Reference: דוגמאות קיימות של קוד, ארכיטקטורה, Testbenches, Quartus configuration,
pin assignments, memory organization ו-peripherals ממעבדות קודמות.

- אין להעתיק את התיקייה לתוצר הסופי.
- אין לשנות קבצים מקוריים בתוכה ללא צורך.
- המימוש החדש נכתב בתיקיית העבודה של הפרויקט.
- בכל שימוש בקוד משם — לומר מאיזה קובץ בדיוק נלקח הרעיון או המבנה.

## דגש מיוחד על Lab 5

Lab 5 הוא Reference מרכזי. אסור להתחיל לממש רכיב מחדש לפני בדיקה אם קיים לו Reference שם.

בכל עבודה על CPU, Register File, Control, ALU, memory, pipeline, Quartus, ModelSim, SignalTap
או subsystem אחר שהופיע ב-Lab 5 — קודם לבדוק את `Auxiliary/Lab 5` ולהציג איזה קובץ קיים שם
רלוונטי.

- משנים `CONTROL.vhd`? קודם: איזה `CONTROL.vhd` קיים ב-Lab 5, מה ההתנהגות שלו, ומה בדיוק
  משתנה ביחס אליו.
- בונים MCU? לא להמציא מבנה קבצים בלי לבדוק קודם כיצד ה-MCU וה-CPU בנויים במעבדה.
- עובדים על Pipeline? לא לבנות מהתחלה אם קיים Pipeline reference שסופק.

## אין Blind Copy

Reference הוא נקודת התחלה, לא מקור שאסור לשנות. עבור כל Reference לבדוק: האם מתאים
לדרישות הפרויקט הנוכחי; האם ממעבדה ישנה עם דרישות שונות; האם הכתובות מתאימות; רוחב
ה-Data Path; ה-Clock assumptions; RV32I או RV32IM; Single Cycle או Pipeline; Hardcoded
paths; Generated artifacts שלא צריכים להיכנס; Bugs או מגבלות ידועות.

## אימות ברמת קובץ

לפני יצירת קובץ חדש להציג:

- **Proposed file** — שם הקובץ.
- **Purpose** — תפקידו.
- **Reference** — הקבצים הקיימים שעליהם הוא מבוסס.
- **Changes from reference** — מה משתנה.
- **Why the change is required** — איזו דרישה מחייבת את השינוי.
- **Verification** — איך נוכיח שהשינוי עובד.

רק לאחר הניתוח — לכתוב קוד. אם אין Reference קיים, לכתוב במפורש
**No direct course reference found**, ואז להסביר כיצד מתוכנן הרכיב ועל איזה מקור הנדסי
הוא מסתמך.

## אימות מול Specification

בכל מימוש של Register, Address, Bit Field, Interrupt source, Timer mode, UART control,
GPIO mapping או Memory behavior — לבדוק את הערך מול חומר אמיתי.

לא להמציא כתובת. לא לנחש Bit Position. לא להניח Interrupt priority. לא לנחש Clock frequency.
לא להניח משמעות של Register לפי שמו.

אם ההגדרה אינה ברורה — לחפש Reference נוסף בחומרי הקורס. אם עדיין קיימת סתירה — **להציג
אותה, לא לבחור Interpretation בשקט.**

## עבודה בשלבים קטנים

לא לממש את כל הפרויקט במכה אחת. כל שלב: Input, שינוי מוגדר, Verification.

בכל שלב: בדיקת החומרים → הצגת References → הסבר מה עומדים לעשות → שינוי קטן → Compile →
Run simulation → בדיקת Waveform או Self Checking assertions → השוואה ל-Expected behavior.
רק אם השלב עבר — ממשיכים.

**אם Test נכשל, לא לפתח רכיבים נוספים לפני שה-Failure מובן.**

## Baseline לפני שינוי קוד

לפני שינויים משמעותיים — לוודא Baseline עובד של החומרים שסופקו. מתבססים על Lab 5
Single Cycle? קודם לוודא שהגרסה המקורית מתקמפלת ורצה עם Test מוכר. קיים Pipeline? לבדוק
שגם הוא מתקמפל כפי שסופק.

המטרה: להפריד בין בעיה שהייתה כבר ב-Reference, בעיה מהשינויים שלנו, בעיה בסביבת
ModelSim/Quartus, ובעיה ב-RTL.

## אין המצאת קבצים

אם נדרש קובץ — קודם לוודא שהוא באמת דרוש. לא לייצר שמות כמו `interrupt_controller.vhd`,
`memory_subsystem.vhd`, `cdc_bridge.vhd`, `gpio_controller.vhd` רק משום שהם הגיוניים.
ייתכן שהפונקציונליות נמצאת בחומר הקיים בתוך קובץ אחר, או שהמרצה מצפה למבנה שונה.
קודם לבדוק את מבנה הפרויקט והרפרנסים; אם אחרי הבדיקה נכון ליצור קובץ חדש — להסביר למה
ההפרדה מוצדקת.

## Verification Driven Development

לכל רכיב שמתווסף צריך להיות ברור איך בודקים אותו:

- **ALU / ISA instruction** — Directed Test.
- **DTCM / MMIO** — addresses, access sizes, aliasing.
- **GPIO** — writes ו-reads.
- **Timer** — Compare, PWM, Capture, Interrupt behavior.
- **Divider** — operands רגילים, edge cases, latency.
- **Interrupt Controller** — masking, priority, simultaneous interrupts, return behavior,
  IFG clearing.
- **Pipeline** — forwarding, stalls, flushes, precise interrupts.
- **UART** — TX, RX, baud rate, framing, buffering, errors, interrupts.

להעדיף Self Checking Testbench על בדיקה ידנית של Waveform. Waveform נועד להוכחה
ו-Debugging; Pass/Fail צריך להיות אוטומטי ככל האפשר.

## Benchmarks הם Contract

Benchmark שסופק בקורס הוא Reference מרכזי. לפני שינוי RTL בגלל Benchmark שנכשל — לבדוק:
Assembly source, ITCM, DTCM, `io_map.s`, Expected output, RARS output אם קיים,
Testbench behavior.

לא להניח מיד שה-RTL שלנו שגוי. אם נראה שה-Benchmark מכיל Bug או סתירה — לשמור את המקור
ללא שינוי ולהציג את הבעיה. גרסה מתוקנת לצורך Verification חייבת להיות נפרדת ומסומנת בבירור.

## Traceability

לאורך כל הפרויקט צריך להיות אפשר לענות על "למה הקוד הזה נראה ככה?" בתשובה ברורה, למשל:
"ה-Address decoder מבוסס על ה-MMIO map ב-Final Project definition"; "ה-CPU top מבוסס על
`RV32IM_sc` מ-Lab 5"; "ה-Pipeline hazard logic נלקח מה-Pipeline שסופק והורחב לתמיכה ב-divider
stall". הקשר בין Requirement, Reference, Implementation ו-Verification חייב להיות ברור.

## אל תסמוך על התוכנית הקיימת באופן עיוור

`rv32im_mcu_project_0a7e2b8a.plan.md` הוא **Roadmap, לא Specification.** אם יש בו טענה, לא
להניח שהיא נכונה רק משום שהיא כתובה שם — לבדוק את המקור שלה.

בכל שלב להבדיל במפורש בין חמש הקטגוריות, ולא לערבב ביניהן:

1. דרישה רשמית של הפרויקט.
2. קוד קיים שסופק על ידי חנן.
3. מסקנה שנובעת מ-Benchmark.
4. Design decision שלנו.
5. Engineering recommendation.

## פורמט חובה לפני כל שלב משמעותי

- **Goal** — מטרת השלב.
- **Relevant requirements** — הדרישות הרשמיות הקשורות.
- **Existing references found** — רשימת הקבצים והחומרים הרלוונטיים.
- **What can be reused** — מה אפשר לקחת מהקוד הקיים.
- **What must be developed** — מה באמת חסר.
- **Open questions or conflicts** — סתירות, חוסרים, ופרשנויות לא ברורות.
- **Verification plan** — איזה Test או Benchmark יוכיח שהשלב הסתיים.
- **Files expected to change** — אילו קבצים קיימים ישתנו ואילו חדשים באמת צריכים להיווצר.

רק לאחר שהניתוח מבוסס מספיק — מתקדמים למימוש.

---

המטרה אינה רק לגרום לפרויקט לעבוד, אלא להגיע למימוש שבו כל חלק ניתן להצדקה מול
Specification, Reference אמיתי ו-Verification ברור.
