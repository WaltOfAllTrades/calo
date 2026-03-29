

// Calorie Entry Pad Component - Number Pad Buttons Only

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');

    // Create keypad container
    const keypad = document.createElement('div');
    keypad.id = 'keypad';
    app.appendChild(keypad);

    // Keypad layout with display-value mapping
    const keyDefs = [
        { display: '1', value: '1' }, { display: '2', value: '2' }, { display: '3', value: '3' },
        { display: '4', value: '4' }, { display: '5', value: '5' }, { display: '6', value: '6' },
        { display: '7', value: '7' }, { display: '8', value: '8' }, { display: '9', value: '9' },
        { display: '00', value: '00' }, { display: '0', value: '0' }, { display: '↩', value: '✓' }
    ];

    keyDefs.forEach(({ display, value }) => {
        const button = document.createElement('button');
        button.textContent = display;
        button.className = 'key-button';
        if (value === '00') button.className += ' operator';
        if (value === '✓') button.className += ' enter';
        button.addEventListener('click', () => {
            console.log('Key pressed:', value);
            // Dispatch custom event for parent components to listen
            const event = new CustomEvent('keypadPress', { detail: { key: value } });
            document.dispatchEvent(event);
        });
        keypad.appendChild(button);
    });
});