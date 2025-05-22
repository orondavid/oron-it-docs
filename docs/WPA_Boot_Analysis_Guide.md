# מדריך מלא לניתוח אתחול עם Windows Performance Analyzer (WPA)

מדריך זה מספק תהליך שלם מהתקנת הכלים הדרושים ועד לניתוח מדויק של תהליך האתחול במערכת Windows, באמצעות הכלי Windows Performance Analyzer.

---

## ✅ שלב 1: התקנת הכלי Windows Performance Toolkit

1. הורד את Windows ADK מאתר מיקרוסופט:
   - [Windows ADK Download](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)

2. במהלך ההתקנה:
   - סמ״ן **"Windows Performance Toolkit"** בלבד.
   - אין צורך בכלי הפצה אחרים (Deployment Tools וכו').

---

## ✅ שלב 2: הפעלת הקלטה לאתחול (Boot Trace)

פתח חלון CMD כמנהל מערכת (Run as Administrator) והרץ:

```cmd
xbootmgr -trace boot -prepSystem -postBootDelay 60 -resultPath C:\BootTrace
```

> הפקודה תבצע אתחול מחדש לצורך איסוף נתונים.

**הסבר הפרמטרים:**
- `-trace boot`: הקלטת אתחול
- `-prepSystem`: הכנת המערכת לקליטה
- `-postBootDelay 60`: המתנה של 60 שניות אחרי האתחול לאיסוף נתונים נוספים
- `-resultPath`: התיקיה בה ישמרו הקבצים (ניתן לשנות)

---

## ✅ שלב 3: פתיחת Windows Performance Analyzer (WPA)

1. פתח את התוכנה "Windows Performance Analyzer" מהתפריט Start.
2. בחר "File > Open..."
3. טען את קובץ `.etl` שנוצר בנתיב:
   ```
   C:\Windows\System32\boot_BASE+CSWITCH_1.etl
   ```

---

## ✅ שלב 4: הוספת גרפים חיוניים לניתוח

בתוך WPA, בתפריט הצדדי "Graph Explorer":

### הוסף את הגרפים הבאים:
- **Boot Phases** – להציג שלבי אתחול (PreSession, Session, Winlogon וכו')
- **CPU Usage (Precise)** – לזהות תהליכים שצורכים מעבד
- **Disk Usage by Process** – לראות מי מעמיס על הדיסק
- **Services** – לראות אילו שירותים התחילו וכמה זמן לקח להם
- **MainPathBoot** / **PostBoot** (אם זמינים) – זמן אתחול עיקרי ואחריו

ניתן להוסיף גרפים ע״י גרירה לחלון המרכזי או באמצעות לחצן ימני > Add Graph to Analysis View.

---

## ✅ שלב 5: ניתוח תוצאות

### Boot Phases
- גרף צבעוני המציג את שלבי האתחול.
- זיהוי של שלב שנמשך זמן רב (למשל Post Boot שנשאר "תקוע") יכול להצביע על בעיה בתהליך אתחול או שירות שלא הסתיים.

### CPU Usage (Precise)
- מציג את כל התהליכים שפעלו בזמן האתחול.
- מזהים תהליכים עם "Weight" ו-"Count" גבוהים כצרכני מעבד עיקריים.

### Disk Usage by Process
- מזהה תהליכים שעמסו על הדיסק.
- ניתן לראות אם עומס בדיסק חופף לתקופת אתחול.

### Services
- מזהה אילו שירותים התחילו, מתי הסתיימו, ומה היה משך הזמן של כל אחד מהם.
- שירות שנמשך מעל לממוצע (במיוחד לאחר Explorer Init) עשוי להוות צוואר בקבוק.

---

## ✅ שלב 6: מסקנות ופעולות מומלצות

| בעיה אפשרית | פעולה מומלצת |
|--------------|----------------|
| שירות שמופעל מוקדם וצורך משאבים | לדחות את הפעלתו ב-Task Scheduler או Autoruns |
| תוכנת צד ג' צורכת CPU ודיסק | להסיר, לעדכן או לדחות את טעינתה |
| עומס על הדיסק במהלך אתחול | לבדוק זמינות SSD, תוכנות גיבוי, סריקות אנטי-וירוס |

---

## ✅ טיפים נוספים

- תמיד בחר טווח זמן על ציר הזמן (מ-0 ועד שהגרפים מתייצבים) כדי להתמקד באתחול בלבד.
- אפשר להפעיל הקלטות נוספות עם פרמטרים אחרים (כגון `boot+drivers` או `boot+mark`) לקבלת מידע נוסף.

---

למידע נוסף: [Microsoft WPA Docs](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/windows-performance-analyzer)
