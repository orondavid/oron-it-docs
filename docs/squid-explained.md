# הסבר לפקודות התקנת Squid Reverse Proxy

עמוד זה מסביר את משמעות כל פקודה במדריך התקנת Squid כ־Reverse Proxy.

---

## עדכון המערכת

```bash
sudo apt update && sudo apt upgrade -y
```

- `sudo` – מריץ את הפקודה עם הרשאות root
- `apt update` – רענון רשימת החבילות
- `apt upgrade -y` – שדרוג כל החבילות באופן אוטומטי

---

## התקנת Squid

```bash
sudo apt install squid -y
```

- מתקין את חבילת Squid – שרת proxy נפוץ

---

## גיבוי הקובץ המקורי

```bash
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
```

- יוצר עותק גיבוי של קובץ ההגדרות לפני ביצוע שינויים

---

## עריכת קובץ הקונפיגורציה

```bash
sudo nano /etc/squid/squid.conf
```

- פותח את הקובץ לעריכה בעורך טקסט `nano`

---

### הסבר על ההגדרות בקובץ:

```text
http_port 3128 accel vhost allow-direct
```
- מגדיר את הפורט ש־Squid יאזין עליו כ־Reverse Proxy

```text
cache_peer 192.168.1.100 parent 80 0 no-query originserver name=webserver
```
- מגדיר את שרת היעד שאליו מועברת התעבורה

```text
acl our_sites dstdomain yourdomain.com
```
- יוצר ACL (רשימת בקרת גישה) שמאפשרת גישה לדומיין מסוים

```text
http_access allow our_sites
```
- מתיר גישה על סמך הכלל שנקבע למעלה

---

## הפעלת השירות מחדש

```bash
sudo systemctl restart squid
```

- מפעיל מחדש את שירות Squid עם ההגדרות החדשות

```bash
sudo systemctl status squid
```

- מציג את סטטוס השירות: האם פעיל, שגיאות, וכו’

---

## פתיחת פורט 3128 בחומת האש (UFW)

```bash
sudo ufw allow 3128/tcp
```

- מאפשר חיבורים לפורט 3128 בפרוטוקול TCP

---

## בדיקת לוגים של Squid

```bash
sudo tail -f /var/log/squid/access.log
```

- מציג את השורות האחרונות בקובץ לוג הפעולות של Squid בזמן אמת