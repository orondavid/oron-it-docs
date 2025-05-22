# מדריך התקנת שרת ווב על Ubuntu Server

מדריך זה מיועד להתקנה בסיסית של שרת ווב (Apache) על מערכת Ubuntu Server עדכנית.

---

## שלב 1: עדכון מערכת

```bash
sudo apt update && sudo apt upgrade -y
```

---

## שלב 2: התקנת Apache

```bash
sudo apt install apache2 -y
```

בדוק ש-Apache פועל:

```bash
sudo systemctl status apache2
```

---

## שלב 3: פתיחת פורט 80 ו-443 בחומת האש

אם UFW פעיל:

```bash
sudo ufw allow 'Apache Full'
```

בדוק את מצב החומת אש:

```bash
sudo ufw status
```

---

## שלב 4: בדיקת גישה

פתח דפדפן והכנס את כתובת ה-IP של השרת:  
`http://<כתובת-IP>`  
אם Apache מותקן כראוי, תראה דף ברירת מחדל.

---

## שלב 5 (אופציונלי): התקנת PHP

```bash
sudo apt install php libapache2-mod-php -y
```

צור קובץ בדיקה:

```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
```

גש אליו דרך:  
`http://<כתובת-IP>/info.php`

---

## שלב 6 (אופציונלי): התקנת MySQL

```bash
sudo apt install mysql-server -y
sudo mysql_secure_installation
```

---

## סיום

שרת הווב שלך מוכן לפעולה!  
מומלץ להסיר את קובץ info.php לאחר הבדיקה:
```bash
sudo rm /var/www/html/info.php
```