# פתרון תקלות ב־AAD Broker Plugin – התחברות ל־Azure, Teams, Outlook

כאשר מופיעות שגיאות התחברות ל־Microsoft 365, Teams, Outlook או שירותי Azure AD – ייתכן שהבעיה נובעת מהתקלות ברכיב AAD.BrokerPlugin של Windows.

---

## 🟠 תסמינים נפוצים

- לא מצליחים להתחבר ל־Teams / Outlook / OneDrive
- הודעת שגיאה "We couldn't sign you in" או "Something went wrong"
- אימות Office נתקע / נופל בלולאה
- אימות MFA לא מגיב או לא מוצג
- חשבונות "Work or School" קופאים

---

## ✅ פתרון מלא – שלב אחר שלב

---

### 1. 🧹 נתק את החשבון הבעייתי ממערכת ההפעלה

- פתח את ההגדרות (Settings)
- עבור ל־**Accounts > Access work or school**
- בחר את החשבון הבעייתי
- לחץ **Disconnect**

---

### 2. 🔁 נקה את המטמון של Web Credentials

- פתח את **Credential Manager** (ניהול אישורים)
- עבור ל־**Windows Credentials**
- מחק כל פריט שמכיל:
  - `microsoft_account`
  - `SSO_POP_Device`
  - `AzureAD` / `Enterprise`
- כעת עבור ל־**Web Credentials**
- מחק גם שם כל פריט דומה

---

### 3. 🧼 מחיקת Token Cache (לא חובה, למתקדמים)

> 🛑 **זהירות:** פעולה מתקדמת – לשימוש רק כששום דבר אחר לא עזר.

1. פתח את הנתיב:
   ```bash
   %LOCALAPPDATA%\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy
   ```
2. מחק את התיקיות:  
   - `AC`
   - `Settings`
   - `TokenBroker`
3. אתחל את המחשב

---

### 4. 🔑 התחברות מחדש

- פתח את Teams / Outlook
- התחבר מחדש עם החשבון שלך
- אם מתבצע אימות MFA – אשר

---

## 🧩 טיפים נוספים

- ודא שזמן המחשב מדויק (Sync with internet time)
- אם הבעיה חוזרת – נסה `dsregcmd /leave` ואז התחברות מחדש לדומיין Azure

---

## 🟢 פקודת ניתוק מדומיין AAD (מתקדם)

```powershell
dsregcmd /leave
```

לאחר מכן:
- אתחל את המחשב
- פתח הגדרות → Accounts → התחבר מחדש לחשבון Azure

---

פתרונות אלו מטפלים ברוב תקלות ה־SSO / התחברות מול Azure/Office.