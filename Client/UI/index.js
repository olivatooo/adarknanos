// Adarknanos UI Script
// Handles jumpscare and horror effects

// Get elements
const jumpscareElement = document.getElementById('jumpscare');
const jumpscareText = document.getElementById('jumpscare-text');
const distortionOverlay = document.getElementById('distortion-overlay');
const jumpscareSound = document.getElementById('jumpscare-sound');

// Jumpscare messages
const jumpscareMessages = [
    'BLOODHOUND',
    'IT SEES YOU',
    'RUN',
    'TOO CLOSE',
    'BEHIND YOU',
    'NO ESCAPE',
    'WATCHING',
    'FOUND YOU'
];

// Jumpscare function
function triggerJumpscare() {
    console.log('JUMPSCARE TRIGGERED!');
    
    // Random message
    const randomMessage = jumpscareMessages[Math.floor(Math.random() * jumpscareMessages.length)];
    jumpscareText.textContent = randomMessage;
    
    // Show jumpscare
    jumpscareElement.classList.add('active');
    distortionOverlay.classList.add('active');
    
    // Random duration (500ms to 1500ms)
    const duration = 500 + Math.random() * 1000;
    
    // Flash effect with random intervals
    let flashCount = 0;
    const maxFlashes = Math.floor(3 + Math.random() * 5);
    
    const flashInterval = setInterval(() => {
        jumpscareElement.style.opacity = Math.random();
        flashCount++;
        
        if (flashCount >= maxFlashes) {
            clearInterval(flashInterval);
        }
    }, 50);
    
    // Hide after duration
    setTimeout(() => {
        hideJumpscare();
    }, duration);
    
    // Trigger screen shake via event to Lua
    Events.Call('JumpscareTriggered');
}

// Hide jumpscare
function hideJumpscare() {
    jumpscareElement.classList.remove('active');
    distortionOverlay.classList.remove('active');
    jumpscareElement.style.opacity = 0;
}

// Mini jumpscare (just distortion, no full screen)
function triggerMiniJumpscare() {
    distortionOverlay.classList.add('active');
    
    setTimeout(() => {
        distortionOverlay.classList.remove('active');
    }, 200 + Math.random() * 300);
}

// Periodic subtle distortion
function startSubtleDistortion() {
    setInterval(() => {
        if (Math.random() > 0.95) { // 5% chance every interval
            triggerMiniJumpscare();
        }
    }, 2000);
}

// Register functions for Lua to call
Events.Subscribe('TriggerJumpscare', triggerJumpscare);
Events.Subscribe('TriggerMiniJumpscare', triggerMiniJumpscare);

// Start subtle effects
startSubtleDistortion();

console.log('Adarknanos UI loaded - Horror mode active');

