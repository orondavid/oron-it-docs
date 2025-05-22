
# מדריך מלא לעבודה ושינויים NK2 וייצוא לפורמט CSV עבור Outlook

## ✉️ מה ההשלמות?
Outlook שומר את רשימת ההשלמה האוטומטית (Auto-Complete List) בקובץ מיוחד, המכיל את כל הנמענים שאליהם שלחת מייל לאחרונה. בקובצי Outlook הישנים (גרסאות 2003–2010), זה נשמר כקובץ `NK2`, ובגרסאות החדשות יותר – כקובץ `Stream_Autocomplete_*.dat`.

באמצעות הכלי החינמי **NK2Edit** ניתן:
- לפתוח ולערוך קובצי השלמה אוטומטית
- למזג קבצים ממקורות שונים
- לייצא לרשימת CSV
- ולהמיר את זה לקובץ מתאים ליבוא לאנשי קשר ב-Outlook

---

## 🔹 שלב 1: הורדה והתקנה של NK2Edit

1. היכנס לאתר:
   [https://www.nirsoft.net/utils/outlook_nk2_edit.html](https://www.nirsoft.net/utils/outlook_nk2_edit.html)
2. הורד את הגרסה המתאימה למחשב שלך (64-bit לרוב המשתמשים)
3. חלץ את הקבצים והפעל את `nk2edit.exe`

אין צורך בהתקנה – מדובר בתוכנה ניידת (portable).

---

## 🔹 שלב 2: פתיחת קובץ השלמה אוטומטית

1. לחץ על `File > Open .DAT File`
2. נווט לנתיב:
   ```
   %LOCALAPPDATA%\Microsoft\Outlook\RoamCache
   ```
3. בחר את הקובץ שמתחיל ב-
   ```
   Stream_Autocomplete_0_XXXX.dat
   ```
   > ניתן לזהות את הקובץ לפי `LastWriteTime` או גודל הקובץ

---

## 🔹 שלב 3: צפייה ועריכה של הנמענים

לאחר טעינת הקובץ תוכל:
- לראות את כל כתובות המייל שהושלמו אוטומטית בעבר
- לערוך או למחוק רשומות
- לסנן ולמיין לפי דומיין, שם, וכו'

---

## 🔹 שלב 4: מיזוג מספר קבצי השלמה

1. טען את הקובץ הראשון ב-NK2Edit
2. עבור ל-
   ```
   File > Merge With Another NK2 File
   ```
3. בחר את הקובץ השני שברצונך למזג
4. שמור את הקובץ המאוחד כקובץ חדש:
   ```
   File > Save As
   ```

---

## 🔹 שלב 5: ייצוא לקובץ CSV

1. סמן את כל השורות (`Ctrl+A`)
2. עבור ל:
   ```
   File > Export Selected Items To Text File
   ```
3. בחר `Comma Delimited Text File (*.csv)`
4. שמור את הקובץ במיקום נוח במחשב

> כעת נוצר קובץ CSV הכולל שמות וכתובות מייל – אך לא בפורמט ש-Outlook מזהה.

---

## 🔹 שלב 6: המרה לקובץ CSV בפורמט Outlook

Outlook דורש מבנה מאוד מסוים, לדוגמה:
```
First Name,Last Name,E-mail Address
Avi,,avi@example.com
```

### ✅ אפשרות א': שימוש באקסל
1. פתח את קובץ ה-CSV שייצאת מ-NK2Edit ב-Excel
2. צור עמודות חדשות בשם:
   - `First Name`
   - `E-mail Address`
3. העתק את שמות הנמענים לעמודת `First Name`, ואת כתובת המייל לעמודת `E-mail Address`
4. שמור את הקובץ כ:
   ```
   CSV UTF-8 (Comma delimited) (*.csv)
   ```

### ✅ אפשרות ב': שימוש בסקריפט PowerShell

למשתמשים מתקדמים – ניתן לבצע המרה אוטומטית באמצעות הסקריפט הבא:

```powershell
# נתיב לקובץ שנוצר מ-NK2Edit
$nk2Path = "C:\Path\To\contact-from-NK2.csv"

# נתיב לקובץ הפלט
$outputPath = "C:\Path\To\contact-for-outlook.csv"

# קריאה של הקובץ
$nk2 = Import-Csv -Path $nk2Path -Header "Type", "Email", "Name"

# עמודות מבנה Outlook
$columns = @(
  "First Name", "Middle Name", "Last Name", "Title", "Suffix", "Nickname",
  "Given Yomi", "Surname Yomi", "E-mail Address", "E-mail 2 Address", "E-mail 3 Address",
  "Home Phone", "Business Phone", "Mobile Phone", "Company", "Job Title", "Business Street",
  "Business City", "Business State", "Business Postal Code", "Business Country/Region",
  "Home Street", "Home City", "Home State", "Home Postal Code", "Home Country/Region",
  "Other Street", "Other City", "Other State", "Other Postal Code", "Other Country/Region",
  "Personal Web Page", "Spouse", "Schools", "Hobby", "Location", "Web Page",
  "Birthday", "Anniversary", "Notes"
)

# המרה לשורות במבנה החדש
$contacts = foreach ($row in $nk2) {
    $obj = [ordered]@{}
    foreach ($col in $columns) {
        switch ($col) {
            "First Name"       { $obj[$col] = $row.Name }
            "E-mail Address"   { $obj[$col] = $row.Email }
            default            { $obj[$col] = "" }
        }
    }
    New-Object PSObject -Property $obj
}

# שמירה לקובץ ב-UTF8 עם BOM (נתמך ב-Outlook Web)
$Utf8WithBomEncoding = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllLines($outputPath, ($contacts | ConvertTo-Csv -NoTypeInformation), $Utf8WithBomEncoding)

Write-Output "✔️ הקובץ נוצר בהצלחה: $outputPath"
```

---

## 🔹 שלב 7: ייבוא ל-Outlook

ב-Outlook:

1. עבור ל"אנשי קשר"

2. לחץ על `ייבוא אנשי קשר`

3. בחר את קובץ ה-CSV שהכנת

4. לחץ על "הבא" והשלם את הפעולה

---

## 🔍 טיפים חשובים:
- ודא שהקובץ הסופי נשמר ב-UTF-8 עם BOM (אקסל שומר זאת אוטומטית כשבוחרים UTF-8)
- הימנע מהוספת עמודות מיותרות או שינויים בשמות הכותרות
- תמיד כדאי לבדוק את הקובץ לפני הייבוא – אפשר לפתוח ב-Notepad או Excel

---

## 📁 קישורים שימושיים
- [NK2Edit - אתר רשמי](https://www.nirsoft.net/utils/outlook_nk2_edit.html)
- [מסמכי תמיכה של Outlook לייבוא אנשי קשר](https://support.microsoft.com/he-il/office/)

---

בהצלחה ביצירת אנשי קשר מסודרים ומקצועיים מתוך ההשלמה האוטומטית ✉️
