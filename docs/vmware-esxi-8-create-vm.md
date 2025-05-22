
# מדריך: יצירת מכונה וירטואלית ב־VMware ESXi 8

מדריך זה מסביר כיצד ליצור מכונה וירטואלית (VM) בסביבת VMware ESXi 8, כולל תמונות אמיתיות מהמערכת.

---

## 🟢 שלב 1: התחברות ל־Web Client

התחבר ל־ESXi דרך כתובת ה־IP בדפדפן, לדוגמה:

```
https://192.168.1.100
```

*הזן את שם המשתמש והסיסמה שלך כדי להתחבר לממשק הניהול.*

---

## 🟢 שלב 2: העלאת ISO ל־Datastore

1. עבור ל־**Storage > Datastores**
2. בחר Datastore קיים
3. לחץ על **Datastore browser**
4. לחץ **Upload** ובחר את קובץ ה־ISO

![Datastore browser והעלאת ISO](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/upload_iso.jpg)

---

## 🟢 שלב 3: יצירת VM חדש

1. עבור ל־**Virtual Machines**
2. לחץ על **Create / Register VM**
3. בחר באופציה הראשונה: **Create a new virtual machine**

![יצירת VM חדש](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/create_vm_button.png)

---

## 🟢 שלב 4: בחירת שם ו־Guest OS

1. הזן שם למכונה (למשל `Ubuntu-Server`)
2. בחר:
   - Compatibility: ברירת מחדל
   - Guest OS family: `Linux`
   - Guest OS version: `Ubuntu Linux (64-bit)`

![Guest OS Selection](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/vm_details.png)

---

## 🟢 שלב 5: בחירת אחסון

בחר את הדאטאסטור שבו יישמר הדיסק של המכונה הווירטואלית.

![Select storage](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/select_storage.png)

---

## 🟢 שלב 6: הגדרות חומרה

הגדר את פרטי החומרה של המכונה:
- CPU: לדוגמה 2 ליבות
- זיכרון (RAM): 2048MB
- דיסק: 20GB (או יותר לפי הצורך)

![Customize hardware](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/hardware_settings.png)

---

## 🟢 שלב 7: קביעת קובץ ISO

1. בקטגוריה CD/DVD Drive לחץ על **Datastore ISO file**
2. בחר את קובץ ה־ISO שהעלית קודם לכן

![Select ISO](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/select_iso.png)

---

## 🟢 שלב 8: סיום והפעלה

1. לחץ **Finish**
2. לחץ **Power on** על ה־VM החדש כדי להתחיל בהתקנת מערכת ההפעלה

![Power on VM](https://raw.githubusercontent.com/oronmadar/assets/main/esxi/power_on_vm.png)

---

כעת המכונה מוכנה, תוכל להיכנס ל־Console ולהתחיל בהתקנת מערכת ההפעלה.

---
