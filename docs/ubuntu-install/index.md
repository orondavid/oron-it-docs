# מדריך התקנת Ubuntu Server

מדריך זה יסביר כיצד להוריד, להכין ולהתקין מערכת הפעלה Ubuntu Server – כולל הכנה בסיסית לאחר ההתקנה.

---

## 🟢 שלב 1: הורדת ISO

- עבור לאתר הרשמי:  
🔗 https://ubuntu.com/download/server

- הורד את הגרסה האחרונה של Ubuntu Server (לרוב LTS)

---

## 🟢 שלב 2: יצירת דיסק USB אתחול

- הורד את **Rufus**: https://rufus.ie
- חבר דיסק און קי (לפחות 4GB)
- בחר את קובץ ה־ISO
- צור את הדיסק עם ברירת המחדל (GPT / UEFI או BIOS בהתאם למחשב)

---

## 🟢 שלב 3: אתחול והתקנה



## 🟦 *. Language (שפה)

בחר את השפה שבה תוצג ההתקנה.  
**מומלץ:** English

![Language Selection](https://www.linuxtechi.com/wp-content/uploads/2022/05/Language-Selection-During-Ubuntu-22-04-Server-Installation.png)

---

## 🟦 *. Keyboard Layout (פריסת מקלדת)

בחר את פריסת המקלדת שלך. תוכל גם לבדוק את הפריסה.  
**לדוברי עברית:** Hebrew

![Keyboard Layout](https://www.linuxtechi.com/wp-content/uploads/2022/05/Keyboard-Layout-During-Ubuntu-22-04-Server-Installation.png)

---

## 🟦 *. Installation Type

בחר את סוג ההתקנה:

- **Ubuntu Server** – התקנה מלאה
- **Ubuntu Server (minimized)** – התקנה מינימלית

**מומלץ:** Ubuntu Server

![Installation Type](https://www.linuxtechi.com/wp-content/uploads/2022/05/Select-Ubuntu-Server-Type-Installation.png)

---

## 🟦 *. Network Connections

המערכת תנסה להגדיר רשת אוטומטית (DHCP).  
תוכל לבחור "Edit IPv4" להגדרת IP סטטי.  
**מומלץ:** להגדיר IP סטטי לשרתים קבועים.

![Network Settings](https://www.linuxtechi.com/wp-content/uploads/2022/05/Network-Settings-During-Ubuntu-22-04-Server-Installation.png)

---

## 🟦 *. Proxy Address

אם הרשת שלך משתמשת ב־Proxy – הזן את הכתובת כאן.  
אם לא – השאר ריק ולחץ Enter.

![Proxy Settings](https://www.linuxtechi.com/wp-content/uploads/2022/05/Proxy-Server-Details-During-Ubuntu-22-04-Installation.png)

---

## 🟦 *. Mirror Address

המערכת תבחר אוטומטית שרת קרוב.  
**אם אין דרישה אחרת – השאר ברירת מחדל.**

![Mirror Settings](https://www.linuxtechi.com/wp-content/uploads/2022/05/Ubuntu-Archive-Mirror-Ubuntu-22-04-Server.png)

---

## 🟦 *. Storage Configuration

בחר את הדיסק להתקנה:

- **Use an entire disk** – פריסה אוטומטית
- **Custom storage layout** – לפריסה ידנית

**למתחילים:** Use an entire disk  
**שימו לב:** פעולה זו תפרמט את כל הדיסק!

![Storage Selection](https://www.linuxtechi.com/wp-content/uploads/2022/05/Use-Entire-Disk-Partitions-Ubuntu-22-04-Server.png)

---

## 🟦 *. Profile Setup

הזן את פרטי המשתמש:

- Name
- Hostname
- Username
- Password

![Profile Setup](https://www.linuxtechi.com/wp-content/uploads/2022/05/Profile-Setup-During-Ubuntu-22-04-Server-Installation.png)

---

## 🟦 *. Install OpenSSH Server

אפשר התקנה של שרת SSH להתחברות מרחוק.  
**מומלץ:** לסמן את האפשרות Install OpenSSH Server.

![Install OpenSSH](https://www.linuxtechi.com/wp-content/uploads/2022/05/Choose-Install-OpenSSH-Server-During-Ubuntu-Server-22-04-Installation.png)

---

## 🟦 *. Featured Server Snaps

ניתן לבחור חבילות Snap נוספות כמו:

- Docker
- Nextcloud
- MicroK8s

**אם אינך בטוח – לחץ Continue.**

![Snap Selection](https://www.linuxtechi.com/wp-content/uploads/2022/05/Server-Snaps-Ubuntu-22-04-Server-Installation.png)

---

## 🟦 *. Installation Progress

לאחר אישור – ההתקנה תחל.  
משך זמן משוער: 5–15 דקות.

![Installing](https://www.linuxtechi.com/wp-content/uploads/2022/05/Installing-Ubuntu-22-04-Server.png)

---

## 🟦 *. Reboot

בסיום תתבקש להוציא את מדיית ההתקנה ולבצע הפעלה מחדש.

![Reboot](https://www.linuxtechi.com/wp-content/uploads/2022/05/Reboot-After-Ubuntu-22-04-Installation.png)

---

לאחר אתחול – תיכנס למערכת Ubuntu Server החדשה שלך 🎉

## 🟢 שלב 4: התחברות למערכת לאחר ההתקנה

- לאחר האתחול, היכנס עם המשתמש שיצרת
- תריץ:

```bash
ip a
```

כדי לבדוק את כתובת ה-IP שלך  
(כדי להתחבר מרחוק ב־SSH אם נדרש)

---

## 🟢 שלב 5: עדכון המערכת

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🟢 שלב 6: התקנת SSH (אם לא סומן בהתקנה)

```bash
sudo apt install openssh-server -y
```

בדוק את השירות:

```bash
sudo systemctl status ssh
```

---

כעת יש לך שרת Ubuntu בסיסי מוכן לשימוש.