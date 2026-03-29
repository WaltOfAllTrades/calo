// Storage utilities for Calo app

const STORAGE_KEY = 'caloData';

function saveCaloData(data) {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        console.log('Data saved:', data);
    } catch (error) {
        console.error('Error saving data:', error);
    }
}

function loadCaloData() {
    try {
        const data = localStorage.getItem(STORAGE_KEY);
        return data ? JSON.parse(data) : null;
    } catch (error) {
        console.error('Error loading data:', error);
        return null;
    }
}

function getDefaultCaloData() {
    const today = new Date();
    const dateString = today.toISOString().split('T')[0]; // YYYY-MM-DD format
    return {
        date: dateString,
        calLogged: 0,
        calTarget: 2000
    };
}

function initializeCaloData() {
    let data = loadCaloData();
    const today = new Date();
    const dateString = today.toISOString().split('T')[0]; // YYYY-MM-DD
    if (!data) {
        data = getDefaultCaloData();
        saveCaloData(data);
    } else if (data.date !== dateString) {
        // New day: reset calories logged and update date
        data.date = dateString;
        data.calLogged = 0;
        saveCaloData(data);
    }
    return data;
}

// Export functions for use in other modules
window.saveCaloData = saveCaloData;
window.loadCaloData = loadCaloData;
window.initializeCaloData = initializeCaloData;

// Initialize data on page load
document.addEventListener('DOMContentLoaded', () => {
    initializeCaloData();
});