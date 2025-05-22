
# 🔧 בדיקות תחזוקה וביצועים ב-Windows (PowerShell)

בדף זה מופיעות פקודות שימושיות לאבחון ותחזוקת מערכת Windows באמצעות PowerShell. הפקודות כוללות בדיקות תקינות קבצים, זיהוי סוג דיסק, מדידת זמן אתחול ובדיקת מהירות אינטרנט. הפקודות באנגלית, וההסברים בעברית.

---

## 🧪 בדיקת תקינות קבצי מערכת

### SFC - סריקה ותיקון קבצי מערכת

```powershell
sfc /scannow
```

פקודה זו סורקת את קבצי מערכת Windows ובודקת אם יש קבצים פגומים או חסרים. אם נמצאו – הם מוחלפים בעותקים תקינים מהמערכת.

---

### DISM - תיקון תמונת מערכת

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
```

משמשת לתיקון תמונת המערכת (Windows Image) במקרה ש־SFC לא מצליח לשחזר קבצים בגלל תמונה פגומה.

---

## 💽 בדיקת סוג דיסק (SSD או HDD)

```powershell
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size
```

מציג את הכוננים הפיזיים ומציין האם מדובר ב־SSD או HDD.

---

## 🕒 מדידת זמן אתחול המערכת

סקריפט שמושך את Event ID 100 מתוך יומן האתחול ומחשב את משך האתחול הכולל, את זמן הליבה ואת זמן ההגעה למסך הלוגין.

```powershell
$event = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 1
$props = $event.Properties | ForEach-Object { $_.Value }

$bootTimeMs = [int]$props[5]
$mainBootMs = [int]$props[6]
$logonMs    = [int]$props[19]

$bootSec  = [math]::Round($bootTimeMs / 1000, 1)
$mainSec  = [math]::Round($mainBootMs / 1000, 1)
$logonSec = [math]::Round($logonMs / 1000, 1)

Write-Host ("{0,-25}: {1,6} ms (~{2} sec)" -f "🖥️ Total Boot Time", $bootTimeMs, $bootSec)
Write-Host ("{0,-25}: {1,6} ms (~{2} sec)" -f "🔄 Main Path Boot Time", $mainBootMs, $mainSec)
Write-Host ("{0,-25}: {1,6} ms (~{2} sec)" -f "🔐 Time to Logon Screen", $logonMs, $logonSec)
```

---

## 📶 בדיקת מהירות אינטרנט (Speedtest CLI)

### שלבים:

1. הורד את הכלי:
   [לחץ כאן להורדה](https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip)

2. חלץ את הקובץ `speedtest.exe` מתוך הקובץ ZIP ושמור אותו בתיקיה לדוגמה `C:\Tools\`.

3. הרץ את הפקודה:
```powershell
C:\Tools\speedtest.exe
```

אם שמרת את הקובץ בתקייה שנמצאת ב־PATH:
```powershell
speedtest
```

---

## 🧩 בדיקת פינג

```powershell
Test-Connection google.com -Count 5
```

בודק זמני תגובה משרת אינטרנט כדי לבדוק קישוריות וביצועים בסיסיים של הרשת.

---

## 🛠️ המרת סקריפט PowerShell לתוכנת EXE באמצעות PS2EXE

הכלי `PS2EXE` מאפשר להמיר סקריפט PowerShell (קובץ `.ps1`) לקובץ הרצה עצמאי (`.exe`) שניתן להפעיל בלחיצה כפולה – גם עם ממשק משתמש (GUI).

### ✅ פקודה לדוגמה:

```powershell
Invoke-ps2exe -InputFile "C:\PS\boot-info-gui.ps1" -OutputFile "C:\PS\boot-info.exe" -NoConsole
```

### 🧾 הסבר רכיבים:

| פרמטר                | תיאור                                                             |
|-----------------------|--------------------------------------------------------------------|
| `Invoke-ps2exe`       | הפקודה שמבצעת את ההמרה                                            |
| `-InputFile`          | הנתיב לקובץ ה־PowerShell המקורי (`.ps1`)                          |
| `-OutputFile`         | הנתיב לקובץ ה־`.exe` שיווצר                                       |
| `-NoConsole`          | מייצר קובץ GUI ללא פתיחת חלון קונסול (Console)                   |

### ⚠️ הערות חשובות:

- הפעל את הפקודה מתוך PowerShell עם הרשאות **מנהל מערכת**.
- אין צורך בהתקנות מיוחדות במחשב שבו מריצים את קובץ ה־EXE שנוצר.
- אם הסקריפט משתמש ב־GUI (`System.Windows.Forms`), חובה להשתמש בפרמטר `-NoConsole`.

---

## 📝 סיכום

בדף זה מוצגים כלים שימושיים לניתוח תקינות מערכת Windows, מדידת זמן אתחול, בדיקת מהירות אינטרנט וזיהוי סוג דיסק – כל זאת באמצעות PowerShell.
