// Debug Component - Displays stored calorie data for debugging

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');

    // Create debug container
    const debugContainer = document.createElement('div');
    debugContainer.id = 'debug-container';
    debugContainer.style.marginTop = '20px';
    debugContainer.style.padding = '10px';
    debugContainer.style.backgroundColor = '#f0f0f0';
    debugContainer.style.borderRadius = '8px';
    debugContainer.style.fontSize = '14px';
    debugContainer.style.fontFamily = 'monospace';

    // Function to update debug display
    function updateDebugDisplay() {
        const data = loadCaloData();
        if (data) {
            debugContainer.innerHTML = `
                <strong>Debug - Stored Data:</strong><br>
                Date: ${data.date}<br>
                Calories Logged: ${data.calLogged}<br>
                Calorie Target: ${data.calTarget}
            `;
        } else {
            debugContainer.innerHTML = '<strong>Debug:</strong> No data stored';
        }
    }

    // Initial display
    updateDebugDisplay();

    // Listen for keypad presses to update display
    document.addEventListener('keypadPress', () => {
        // Small delay to allow storage updates
        setTimeout(updateDebugDisplay, 100);
    });

    // Append to app
    app.appendChild(debugContainer);
});