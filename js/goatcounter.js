window.goatcounter = {
    path: function() {
        return decodeURIComponent(window.location.pathname);
    },
    title: function() {
        // מסיר תווים בעייתיים ומחזיר שם עמוד פשוט
        return document.title.replace(/[^\w\s\-א-ת]/g, '').substring(0, 100);
    },
    referrer: function() {
        // מחזיר כתובת מקור תקינה, או none אם לא קיים
        return document.referrer || 'none';
    }
};

let sc = document.createElement('script');
sc.setAttribute('data-goatcounter', 'https://oron-it.goatcounter.com/count');
sc.src = '//gc.zgo.at/count.js';
sc.async = true;
document.head.appendChild(sc);
