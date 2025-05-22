# התקנת שרת פרוקסי קדמי (Forward Proxy) עם Squid

מדריך זה מסביר כיצד להקים שרת פרוקסי קדמי (Forward Proxy) באמצעות Squid על מערכת Ubuntu.

---

## 🟩 שלב 1: התקנת Squid

```bash
sudo apt update
sudo apt install squid -y
```

---

## 🟩 שלב 2: גיבוי קובץ ההגדרות

```bash
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
```

---

## 🟩 שלב 3: עריכת קובץ ההגדרות

```bash
sudo nano /etc/squid/squid.conf
```

חפש את השורה:

```
http_port 3128
```

ודא שהיא לא מוסתרת (ללא #).

כעת הוסף/שנה את השורות הבאות:

```conf
acl localnet src 192.168.1.0/24
http_access allow localnet
http_access deny all
```

---

## 🟩 שלב 4: הפעלת השירות

```bash
sudo systemctl restart squid
sudo systemctl enable squid
```

---

## 🟩 שלב 5: פתיחת פורט ב־Firewall (אם מופעל)

```bash
sudo ufw allow 3128/tcp
```

---

## 🟩 שלב 6: הגדרת התחברות מהמחשב הלקוח

במחשב שמתחבר דרך הפרוקסי:

- כתובת שרת: IP של השרת
- פורט: 3128
- פרוטוקול: HTTP Proxy

---

## 🟢 טסט מהיר:

מהמחשב של הלקוח הרץ:

```bash
curl -x http://IP-of-proxy:3128 http://example.com
```

---

שרת הפרוקסי שלך מוכן וניתן להשתמש בו כתחנת מעבר לגלישה/גישה לאינטרנט דרך שרת מאובטח.