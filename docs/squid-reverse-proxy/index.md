# התקנת Squid Reverse Proxy על Ubuntu Server

מדריך זה יסביר כיצד להתקין ולהגדיר את Squid כ־Reverse Proxy.

---

## שלב 1: עדכון המערכת

```bash
sudo apt update && sudo apt upgrade -y
```

---

## שלב 2: התקנת Squid

```bash
sudo apt install squid -y
```

---

## שלב 3: גיבוי הקובץ המקורי

```bash
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
```

---

## שלב 4: עריכת קובץ הקונפיגורציה

```bash
sudo nano /etc/squid/squid.conf
```

מחק את תוכן הקובץ והדבק את זה (דוגמה בסיסית ל־Reverse Proxy):

```
http_port 3128 accel vhost allow-direct
cache_peer 192.168.1.100 parent 80 0 no-query originserver name=webserver
acl our_sites dstdomain yourdomain.com
http_access allow our_sites
```

> החלף את `192.168.1.100` בכתובת השרת שאליו תרצה להפנות  
> והחלף `yourdomain.com` בשם הדומיין החיצוני שלך

---

## שלב 5: הפעלת השירות מחדש

```bash
sudo systemctl restart squid
```

בדיקת מצב השירות:

```bash
sudo systemctl status squid
```

---

## שלב 6 (אופציונלי): פתיחת פורט 3128

```bash
sudo ufw allow 3128/tcp
```

---

## סיום

כעת Squid יאזין על פורט 3128 ויפעל כ־Reverse Proxy לכתובת שהוגדרה.  
מומלץ לבדוק את הלוגים הראשונים:

```bash
sudo tail -f /var/log/squid/access.log
```