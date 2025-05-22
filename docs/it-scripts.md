# סקריפטים שימושיים לניהול מערכות

מדריך זה מרכז סקריפטים שימושיים שיכולים לחסוך זמן, לייעל תהליכים ולשפר את העבודה היומיומית של טכנאים ומנהלי IT.

---

## 🪟 PowerShell (Windows)

### 🔹 בדיקת אנטי־וירוס

```powershell
Get-MpComputerStatus | Select AMServiceEnabled, AntispywareEnabled, RealTimeProtectionEnabled
```

### 🔹 מחשבים לא פעילים 30 יום בדומיין

```powershell
Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan 30.00:00:00 | Select Name
```

### 🔹 הפקת דוח מערכת

```powershell
Get-ComputerInfo | Out-File C:\system_info.txt
```

### 🔹 ניקוי הגדרות רשת

```powershell
ipconfig /flushdns
netsh winsock reset
netsh int ip reset
```

---

## 🐧 Bash (Linux)

### 🔹 גיבוי תיקיות

```bash
tar -czvf backup_$(date +%F).tar.gz /etc /home /var/www
```

### 🔹 התרעה על שטח דיסק

```bash
df -h | mail -s "Disk Report" admin@domain.com
```

### 🔹 איתור עומס CPU

```bash
ps -eo pid,comm,%cpu --sort=-%cpu | head
```

### 🔹 מעקב לוגים בזמן אמת

```bash
tail -f /var/log/syslog
```

---

## 🎯 שימושים נפוצים

- תחזוקה שוטפת
- ניטור וזיהוי תקלות
- ניהול משתמשים
- גיבויים ואבטחת מידע

---

> ניתן להעתיק ולהתאים את הסקריפטים לצרכים הספציפיים שלך