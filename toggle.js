// Toggle Component - Pill-shaped toggle with + and - buttons

function createToggle(onToggle = null) {
    // Main container - the pill background
    const pillContainer = document.createElement('div');
    pillContainer.style.display = 'inline-flex';
    pillContainer.style.alignItems = 'center';
    pillContainer.style.gap = '0';
    pillContainer.style.backgroundColor = '#f0f0f0';
    pillContainer.style.borderRadius = '6px';
    pillContainer.style.padding = '0.5px';
    pillContainer.style.width = 'fit-content';

    let isAddMode = true;

    // Plus button
    const plusBtn = document.createElement('button');
    plusBtn.textContent = '+';
    plusBtn.type = 'button';
    plusBtn.className = 'toggle-btn toggle-plus';
    plusBtn.style.width = '20px';
    plusBtn.style.height = '12px';
    plusBtn.style.border = 'none';
    plusBtn.style.borderRadius = '6px';
    plusBtn.style.fontSize = '8px';
    plusBtn.style.fontWeight = 'bold';
    plusBtn.style.cursor = 'pointer';
    plusBtn.style.transition = 'all 0.2s ease';
    plusBtn.style.padding = '0';
    plusBtn.style.display = 'flex';
    plusBtn.style.alignItems = 'center';
    plusBtn.style.justifyContent = 'center';
    // Initial styles will be set by updateDisplay()

    // Minus button
    const minusBtn = document.createElement('button');
    minusBtn.textContent = '−';
    minusBtn.type = 'button';
    minusBtn.className = 'toggle-btn toggle-minus';
    minusBtn.style.width = '20px';
    minusBtn.style.height = '12px';
    minusBtn.style.border = 'none';
    minusBtn.style.borderRadius = '6px';
    minusBtn.style.fontSize = '8px';
    minusBtn.style.fontWeight = 'bold';
    minusBtn.style.cursor = 'pointer';
    minusBtn.style.transition = 'all 0.2s ease';
    minusBtn.style.padding = '0';
    minusBtn.style.display = 'flex';
    minusBtn.style.alignItems = 'center';
    minusBtn.style.justifyContent = 'center';
    // Initial styles will be set by updateDisplay()

    function updateDisplay() {
        console.log('updateDisplay called, isAddMode:', isAddMode);
        
        if (isAddMode) {
            // Plus button active (blue)
            plusBtn.style.backgroundColor = '#007aff';
            plusBtn.style.color = 'white';
            
            // Minus button inactive (transparent/grey)
            minusBtn.style.backgroundColor = 'transparent';
            minusBtn.style.color = '#999';
            
            console.log('Set plus active (blue), minus inactive (grey)');
        } else {
            // Plus button inactive (transparent/grey)
            plusBtn.style.backgroundColor = 'transparent';
            plusBtn.style.color = '#999';
            
            // Minus button active (blue)
            minusBtn.style.backgroundColor = '#007aff';
            minusBtn.style.color = 'white';
            
            console.log('Set plus inactive (grey), minus active (blue)');
        }
    }

    // Individual button clicks are now handled by the container click listener above
    // No need for separate button listeners

    pillContainer.appendChild(plusBtn);
    pillContainer.appendChild(minusBtn);

    // Handle clicks anywhere within the toggle bounds - toggle the current state
    pillContainer.addEventListener('click', (e) => {
        console.log('Toggle container clicked - toggling state');
        
        // Simply toggle between add and subtract modes
        isAddMode = !isAddMode;
        updateDisplay();
        if (onToggle) onToggle(isAddMode);
    });

    // Set initial visual state
    updateDisplay();

    // Create a mock input object for compatibility
    const mockInput = {
        get checked() {
            return isAddMode;
        },
        set checked(value) {
            if (value !== isAddMode) {
                isAddMode = value;
                updateDisplay();
            }
        }
    };

    return {
        container: pillContainer,
        input: mockInput,
        setMode: (isAdd) => {
            isAddMode = isAdd;
            updateDisplay();
            if (onToggle) onToggle(isAdd);
        },
        getMode: () => isAddMode
    };
}

// Export for use in other components
window.createToggle = createToggle;