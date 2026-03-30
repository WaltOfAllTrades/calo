// Show a message if the device is too small to render the app
(function() {
    function checkScreenSize() {
        const minWidth = 350;
        const minHeight = 580;
        const app = document.getElementById('app');
        let warning = document.getElementById('screen-size-warning');
        if (window.innerWidth < minWidth || window.innerHeight < minHeight) {
            if (!warning) {
                warning = document.createElement('div');
                warning.id = 'screen-size-warning';
                warning.style.position = 'fixed';
                warning.style.top = '0';
                warning.style.left = '0';
                warning.style.width = '100vw';
                warning.style.height = '100vh';
                warning.style.background = '#fff';
                warning.style.display = 'flex';
                warning.style.justifyContent = 'center';
                warning.style.alignItems = 'center';
                warning.style.zIndex = '99999';
                warning.style.fontSize = '1.3rem';
                warning.style.fontWeight = 'bold';
                warning.style.textAlign = 'center';
                warning.textContent = 'Current device screen is too small to render app. Please use another device.';
                document.body.appendChild(warning);
            }
            if (app) app.style.visibility = 'hidden';
        } else {
            if (warning) warning.remove();
            if (app) app.style.visibility = '';
        }
    }
    window.addEventListener('resize', checkScreenSize);
    window.addEventListener('orientationchange', checkScreenSize);
    document.addEventListener('DOMContentLoaded', checkScreenSize);
})();
