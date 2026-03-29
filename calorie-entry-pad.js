

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
        { display: '00', value: '00' }, { display: '0', value: '0' }, { display: 'svg', value: '✓' }
    ];

    keyDefs.forEach(({ display, value }) => {
        const button = document.createElement('button');
        button.className = 'key-button';
        if (value === '00') button.className += ' operator';
        if (value === '✓') button.className += ' enter';
        if (value === '✓') {
            button.innerHTML = `<svg height="32px" viewBox="0 -960 960 960" width="32px" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="m 564,-800 c 64.66667,0 120.16667,21 166.5,63 46.33333,42 69.5,94.33333 69.5,157 0,62.66667 -23.16667,115 -69.5,157 -46.33333,42 -101.83333,63 -166.5,63 H 312 l 104,104 -56,56 -200,-200 200,-200 56,56 -104,104 h 252 c 42,0 78.5,-13.33333 109.5,-40 31,-26.66667 46.5,-60 46.5,-100 0,-40 -15.5,-73.33333 -46.5,-100 -31,-26.66667 -67.5,-40 -109.5,-40 z"/></svg>`;
        } else {
            button.textContent = display;
        }
        button.addEventListener('click', () => {
            console.log('Key pressed:', value);
            // Dispatch custom event for parent components to listen
            const event = new CustomEvent('keypadPress', { detail: { key: value } });
            document.dispatchEvent(event);
        });
        keypad.appendChild(button);
    });
});