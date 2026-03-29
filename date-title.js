// Date Title Component - Displays current date in "Day Month, Day" format

function getFormattedDate() {
    const now = new Date();
    const options = {
        weekday: 'long',
        month: 'long',
        day: 'numeric'
    };
    return now.toLocaleDateString('en-US', options);
}

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');

    // Create date title container
    const dateTitleContainer = document.createElement('div');
    dateTitleContainer.id = 'date-title-container';
    dateTitleContainer.style.position = 'relative';
    dateTitleContainer.style.marginBottom = '20px';

    // Menu button (top left, no background)
    const menuBtn = document.createElement('button');
    menuBtn.style.position = 'absolute';
    menuBtn.style.left = '0';
    menuBtn.style.top = '50%';
    menuBtn.style.transform = 'translateY(-50%)';
    menuBtn.style.width = '40px';
    menuBtn.style.height = '40px';
    menuBtn.style.borderRadius = '50%';
    menuBtn.style.border = 'none';
    menuBtn.style.backgroundColor = 'transparent';
    menuBtn.style.cursor = 'pointer';
    menuBtn.style.display = 'flex';
    menuBtn.style.alignItems = 'center';
    menuBtn.style.justifyContent = 'center';
    menuBtn.style.flexShrink = '0';
    menuBtn.style.padding = '0';

    // Create menu icon using external SVG file
    const menuImg = document.createElement('img');
    menuImg.src = 'menu.svg';
    menuImg.style.width = '24px';
    menuImg.style.height = '24px';

    menuBtn.appendChild(menuImg);

    menuBtn.addEventListener('click', () => {
        console.log('Menu clicked');
    });

    // Create date title element
    const dateTitle = document.createElement('div');
    dateTitle.id = 'date-title';
    dateTitle.textContent = getFormattedDate();
    dateTitle.style.fontSize = '18px';
    dateTitle.style.fontWeight = 'bold';
    dateTitle.style.color = '#333';
    dateTitle.style.textAlign = 'center';

    // Add elements to container
    dateTitleContainer.appendChild(menuBtn);
    dateTitleContainer.appendChild(dateTitle);

    // Insert at the top of the app
    app.insertBefore(dateTitleContainer, app.firstChild);
});