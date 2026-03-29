// Input Component - Settings and toggle row with text input below

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');

    // Main input container
    const inputContainer = document.createElement('div');
    inputContainer.id = 'input-container';
    inputContainer.style.display = 'flex';
    inputContainer.style.flexDirection = 'column';
    inputContainer.style.gap = '12px';
    inputContainer.style.marginBottom = '20px';
    inputContainer.style.width = '100%';

    // Create toggle
    const { container: toggleContainer, input: toggleInput, setMode } = createToggle((isAdd) => {
        console.log('Toggle callback called with isAdd:', isAdd);
        isAddMode = isAdd;
        console.log('isAddMode updated to:', isAddMode);
    });

    let isAddMode = true;


    // Wrapper to center input and toggle visually
    const inputWrapper = document.createElement('div');
    inputWrapper.style.position = 'relative';
    inputWrapper.style.display = 'block';
    inputWrapper.style.margin = '0 auto';
    inputWrapper.style.width = '320px'; // match app max-width for perfect centering

    // Place toggle absolutely inside the input field border
    toggleContainer.style.position = 'absolute';
    toggleContainer.style.left = '10px';
    toggleContainer.style.top = '50%';
    toggleContainer.style.transform = 'translateY(-50%)';
    toggleContainer.style.zIndex = '2';

    // Text input field
    const inputField = document.createElement('input');
    inputField.id = 'calorie-input';
    inputField.type = 'text';
    inputField.placeholder = '0';
    inputField.style.width = '100%';
    inputField.style.textAlign = 'right';
    inputField.style.height = '50px';
    inputField.style.borderRadius = '999px';
    inputField.style.border = '1.5px solid #c3c3c3ff';
    inputField.style.padding = '0 20px 0 95px'; // room for toggle inside input
    inputField.style.fontSize = '16px';
    // keep right alignment as requested
    inputField.style.boxSizing = 'border-box';
    inputField.style.backgroundColor = '#f5f5f5f4';
    inputField.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.18)';
    inputField.readOnly = true;

    let currentInput = '';

    // Listen for keypad presses
    document.addEventListener('keypadPress', (event) => {
        const key = event.detail.key;

        if ((key >= '0' && key <= '9') || key === '00') {
            if (key === '00') {
                if (currentInput !== '') {
                    currentInput += '00';
                }
            } else if (currentInput === '0') {
                currentInput = key;
            } else {
                currentInput += key;
            }
        } else if (key === '✓') {
            if (currentInput) {
                const value = parseInt(currentInput);
                console.log('Logging calories:', value, 'in mode:', isAddMode ? 'ADD' : 'SUBTRACT');
                const data = loadCaloData();
                if (data) {
                    const oldLogged = data.calLogged;
                    if (isAddMode) {
                        data.calLogged += value;
                        console.log('Added:', value, '- Old:', oldLogged, 'New:', data.calLogged);
                    } else {
                        data.calLogged -= value;
                        console.log('Subtracted:', value, '- Old:', oldLogged, 'New:', data.calLogged);
                    }
                    saveCaloData(data);
                }
                currentInput = '';
            }
        }

        inputField.value = currentInput;
    });

    // Assemble the component (toggle inside input border)
    inputWrapper.appendChild(inputField);
    inputWrapper.appendChild(toggleContainer);
    inputContainer.appendChild(inputWrapper);
    app.appendChild(inputContainer);

    // Insert before keypad
    const keypad = document.getElementById('keypad');
    if (keypad) {
        app.insertBefore(inputContainer, keypad);
    }
});