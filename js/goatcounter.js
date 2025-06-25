// מונע קידוד כפול של כתובת העמוד (path)
window.goatcounter = {
    path: function() {
        return decodeURIComponent(window.location.pathname);
    }
};

let sc = document.createElement('script');
sc.setAttribute('data-goatcounter', 'https://oron-it.goatcounter.com/count');
sc.src = '//gc.zgo.at/count.js';
sc.async = true;
document.head.appendChild(sc);
