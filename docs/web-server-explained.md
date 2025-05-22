# הסבר לפקודות התקנת שרת ווב על Ubuntu

מדריך זה מסביר מה כל פקודה עושה בתהליך התקנת שרת ווב על Ubuntu Server.

---

## עדכון מערכת

```bash
sudo apt update && sudo apt upgrade -y
```

- `sudo` – מריץ את הפקודה כמשתמש מנהל (root)
- `apt update` – מרענן את רשימת החבילות מהמאגר
- `apt upgrade -y` – משדרג את כל החבילות למעודכנות ביותר, `-y` מאשר אוטומטית

---

## התקנת Apache

```bash
sudo apt install apache2 -y
```

- `apt install apache2` – מתקין את שרת ה־Web Apache

```bash
sudo systemctl status apache2
```

- מציג את מצב השירות – האם רץ, מופעל באתחול וכו'

---

## חומת אש (UFW)

```bash
sudo ufw allow 'Apache Full'
```

- מאפשר תעבורה בפורטים 80 (HTTP) ו־443 (HTTPS) דרך UFW

```bash
sudo ufw status
```

- מציג את מצב החומת אש והחוקים המוגדרים

---

## התקנת PHP

```bash
sudo apt install php libapache2-mod-php -y
```

- מתקין את PHP ואת התמיכה שלו בתוך Apache (מודול mod-php)

```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
```

- יוצר קובץ `info.php` שמציג את הגדרות PHP בדפדפן

---

## התקנת MySQL

```bash
sudo apt install mysql-server -y
```

- מתקין את שרת מסד הנתונים MySQL

```bash
sudo mysql_secure_installation
```

- אשף הגדרות אבטחה בסיסי של MySQL (סיסמה, הסרת משתמשים אנונימיים וכו')

---

## הסרת קובץ בדיקה

```bash
sudo rm /var/www/html/info.php
```

- מוחק את קובץ info.php (מומלץ לאחר השימוש מטעמי אבטחה)

---