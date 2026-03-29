// Stats Display Component - Shows calories remaining and logged

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');

    // Create stats container
    const statsContainer = document.createElement('div');
    statsContainer.id = 'stats-container';
    statsContainer.style.display = 'flex';
    statsContainer.style.justifyContent = 'space-around';
    statsContainer.style.alignItems = 'center';
    statsContainer.style.marginBottom = '30px';
    statsContainer.style.marginTop = '20px';

    // Cal Remaining
    const remainingDiv = document.createElement('div');
    remainingDiv.style.textAlign = 'center';
    const remainingValue = document.createElement('div');
    remainingValue.id = 'cal-remaining';
    remainingValue.style.fontSize = '36px';
    remainingValue.style.fontWeight = 'bold';
    remainingValue.style.color = '#333';
    remainingValue.textContent = '2000';

    const remainingLabel = document.createElement('div');
    remainingLabel.style.fontSize = '14px';
    remainingLabel.style.color = '#666';
    remainingLabel.style.marginTop = '8px';
    remainingLabel.textContent = 'Cal Remaining';

    remainingDiv.appendChild(remainingValue);
    remainingDiv.appendChild(remainingLabel);

    // Cal Logged
    const loggedDiv = document.createElement('div');
    loggedDiv.style.textAlign = 'center';
    const loggedValue = document.createElement('div');
    loggedValue.id = 'cal-logged';
    loggedValue.style.fontSize = '36px';
    loggedValue.style.fontWeight = 'bold';
    loggedValue.style.color = '#333';
    loggedValue.textContent = '0';

    const loggedLabel = document.createElement('div');
    loggedLabel.style.fontSize = '14px';
    loggedLabel.style.color = '#666';
    loggedLabel.style.marginTop = '8px';
    loggedLabel.textContent = 'Cal Logged';

    loggedDiv.appendChild(loggedValue);
    loggedDiv.appendChild(loggedLabel);

    statsContainer.appendChild(remainingDiv);
    statsContainer.appendChild(loggedDiv);

    // Insert after date title
    const dateTitle = document.getElementById('date-title');
    if (dateTitle) {
        dateTitle.parentNode.insertBefore(statsContainer, dateTitle.nextSibling);
    } else {
        app.insertBefore(statsContainer, app.firstChild);
    }

    // Update stats when storage changes
    function updateStats() {
        const data = loadCaloData();
        if (data) {
            const remaining = data.calTarget - data.calLogged;
            document.getElementById('cal-remaining').textContent = remaining;
            document.getElementById('cal-logged').textContent = data.calLogged;
        }
    }

    // Initial update
    updateStats();

    // Listen for keypad presses to update stats
    document.addEventListener('keypadPress', () => {
        setTimeout(updateStats, 100);
    });
});