// Menu Card Component - Shows a card with menu options when the menu button is clicked

(function() {
    // Create the menu overlay and card element
    function createMenuCard() {
        // Overlay (relative to #app)
        const app = document.getElementById('app');
        const overlay = document.createElement('div');
        overlay.id = 'menu-card-overlay';
        overlay.style.position = 'absolute';
        overlay.style.top = '0';
        overlay.style.left = '0';
        overlay.style.width = '100%';
        overlay.style.height = '100%';
        overlay.style.background = 'rgba(0,0,0,0.18)';
        overlay.style.display = 'none';
        overlay.style.zIndex = '9999';
        overlay.style.justifyContent = 'center';
        overlay.style.alignItems = 'center';
        overlay.style.transition = 'background 0.2s';
        overlay.style.flexDirection = 'column';
        overlay.style.pointerEvents = 'auto';
        overlay.style.fontFamily = 'inherit';
        overlay.style.boxSizing = 'border-box';
        overlay.style.padding = '0';
        overlay.style.margin = '0';


        // Card
        const card = document.createElement('div');
        card.id = 'menu-card';
        card.style.background = 'white';
        card.style.borderRadius = '16px';
        card.style.boxShadow = '0 8px 32px rgba(0,0,0,0.18)';
        card.style.padding = '28px 28px 20px 28px';
        card.style.minWidth = '220px';
        card.style.maxWidth = '90vw';
        card.style.zIndex = '10001';
        card.style.display = 'flex';
        card.style.flexDirection = 'column';
        card.style.gap = '18px';
        card.style.position = 'relative';

        // X close button
        const closeBtn = document.createElement('button');
        closeBtn.textContent = '×';
        closeBtn.setAttribute('aria-label', 'Close menu');
        closeBtn.style.position = 'absolute';
        closeBtn.style.top = '10px';
        closeBtn.style.right = '14px';
        closeBtn.style.background = 'none';
        closeBtn.style.border = 'none';
        closeBtn.style.fontSize = '28px';
        closeBtn.style.cursor = 'pointer';
        closeBtn.style.color = '#888';
        closeBtn.style.lineHeight = '1';
        closeBtn.style.padding = '0';
        closeBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            hideMenuCard();
        });
        card.appendChild(closeBtn);


        // Settings button
        const settingsBtn = document.createElement('button');
        settingsBtn.textContent = 'Settings';
        settingsBtn.style.background = 'none';
        settingsBtn.style.border = 'none';
        settingsBtn.style.fontSize = '18px';
        settingsBtn.style.textAlign = 'left';
        settingsBtn.style.padding = '8px 0';
        settingsBtn.style.cursor = 'pointer';
        settingsBtn.style.color = '#333';
        settingsBtn.style.borderRadius = '8px';
        settingsBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            alert('Settings clicked');
            hideMenuCard();
        });
        card.appendChild(settingsBtn);

        // Calorie Target entry field and save button
        const targetForm = document.createElement('form');
        targetForm.style.display = 'flex';
        targetForm.style.flexDirection = 'row';
        targetForm.style.alignItems = 'center';
        targetForm.style.gap = '10px';
        targetForm.style.marginTop = '8px';

        const targetLabel = document.createElement('label');
        targetLabel.textContent = 'Calorie Target';
        targetLabel.style.fontSize = '16px';
        targetLabel.style.color = '#333';
        targetLabel.setAttribute('for', 'menu-calorie-target');

        const targetInput = document.createElement('input');
        targetInput.type = 'number';
        targetInput.id = 'menu-calorie-target';
        targetInput.min = '1';
        targetInput.style.width = '80px';
        targetInput.style.fontSize = '16px';
        targetInput.style.padding = '4px 8px';
        targetInput.style.borderRadius = '6px';
        targetInput.style.border = '1px solid #ccc';
        targetInput.style.boxSizing = 'border-box';
        // Set initial value from storage
        if (window.loadCaloData) {
            const data = window.loadCaloData();
            if (data && typeof data.calTarget === 'number') {
                targetInput.value = data.calTarget;
            }
        }

        const saveBtn = document.createElement('button');
        saveBtn.type = 'submit';
        saveBtn.textContent = 'Save';
        saveBtn.style.background = '#007aff';
        saveBtn.style.color = 'white';
        saveBtn.style.border = 'none';
        saveBtn.style.fontSize = '16px';
        saveBtn.style.borderRadius = '6px';
        saveBtn.style.padding = '6px 16px';
        saveBtn.style.cursor = 'pointer';

        targetForm.appendChild(targetLabel);
        targetForm.appendChild(targetInput);
        targetForm.appendChild(saveBtn);

        targetForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const newTarget = parseInt(targetInput.value, 10);
            if (!isNaN(newTarget) && window.loadCaloData && window.saveCaloData) {
                const data = window.loadCaloData();
                if (data) {
                    data.calTarget = newTarget;
                    window.saveCaloData(data);
                }
                document.dispatchEvent(new CustomEvent('keypadPress', { detail: { key: 'target' } }));
                hideMenuCard();
            }
        });

        card.appendChild(targetForm);

        // Reset Calories button
        const resetBtn = document.createElement('button');
        resetBtn.textContent = 'Reset logged calories';
        resetBtn.className = 'key-button reset-logged-btn';
        resetBtn.style.width = '240px';
        resetBtn.style.height = '40px';
        resetBtn.style.fontSize = '16px';
        resetBtn.style.margin = '16px auto 0 auto';
        resetBtn.style.background = '#fdfdfdff';
        resetBtn.style.color = '#d00';
        resetBtn.style.border = '1.5px solid #cbcbcb';
        resetBtn.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.18)';
        resetBtn.style.display = 'flex';
        resetBtn.style.alignItems = 'center';
        resetBtn.style.justifyContent = 'center';
        resetBtn.style.borderRadius = '999px';
        resetBtn.style.textAlign = 'center';
        resetBtn.style.fontWeight = '500';
        resetBtn.style.transition = 'all 0.1s ease';
        resetBtn.style.cursor = 'pointer';
        resetBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (window.loadCaloData && window.saveCaloData) {
                const data = window.loadCaloData();
                if (data) {
                    data.calLogged = 0;
                    window.saveCaloData(data);
                }
            }
            // Trigger UI refresh for cal remaining and cal logged
            document.dispatchEvent(new CustomEvent('keypadPress', { detail: { key: 'reset' } }));
            hideMenuCard();
        });
        card.appendChild(resetBtn);

        overlay.appendChild(card);
        if (app) {
            app.style.position = 'relative'; // Ensure #app is positioned
            app.appendChild(overlay);
        } else {
            document.body.appendChild(overlay);
        }
        return overlay;
    }

    let menuOverlay = null;

    function showMenuCard() {
        if (!menuOverlay) menuOverlay = createMenuCard();
        menuOverlay.style.display = 'flex';
        setTimeout(() => {
            document.addEventListener('mousedown', handleOutsideClick);
        }, 0);
    }

    function hideMenuCard() {
        if (menuOverlay) menuOverlay.style.display = 'none';
        document.removeEventListener('mousedown', handleOutsideClick);
    }

    function handleOutsideClick(e) {
        if (menuOverlay && !menuOverlay.contains(e.target)) {
            hideMenuCard();
        }
        // If click is on overlay but not on card, close
        if (menuOverlay && e.target === menuOverlay) {
            hideMenuCard();
        }
    }

    // Listen for menu button click
    document.addEventListener('DOMContentLoaded', () => {
        const menuBtn = document.querySelector('#date-title-container button');
        if (menuBtn) {
            menuBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                if (menuOverlay && menuOverlay.style.display === 'flex') {
                    hideMenuCard();
                } else {
                    showMenuCard();
                }
            });
        }
    });

    // Expose for debugging
    window.showMenuCard = showMenuCard;
    window.hideMenuCard = hideMenuCard;
})();
