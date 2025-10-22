// Adarknanos UI Script
// Handles jumpscare and horror effects

// Get elements
const jumpscareElement = document.getElementById("jumpscare");
const jumpscareText = document.getElementById("jumpscare-text");
const distortionOverlay = document.getElementById("distortion-overlay");
const jumpscareSound = document.getElementById("jumpscare-sound");

// Jumpscare messages
const jumpscareMessages = [
  "IT SEES YOU",
  "RUN",
  "TOO CLOSE",
  "BEHIND YOU",
  "NO ESCAPE",
  "WATCHING",
  "FOUND YOU",
];

// Jumpscare function
function triggerJumpscare() {
  const randomMessage =
    jumpscareMessages[Math.floor(Math.random() * jumpscareMessages.length)];
  jumpscareText.textContent = randomMessage;

  // Show jumpscare
  jumpscareElement.classList.add("active");
  distortionOverlay.classList.add("active");

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
  Events.Call("JumpscareTriggered");
}

// Hide jumpscare
function hideJumpscare() {
  jumpscareElement.classList.remove("active");
  distortionOverlay.classList.remove("active");
  jumpscareElement.style.opacity = 0;
}

// Mini jumpscare (just distortion, no full screen)
function triggerMiniJumpscare() {
  distortionOverlay.classList.add("active");

  setTimeout(
    () => {
      distortionOverlay.classList.remove("active");
    },
    200 + Math.random() * 300,
  );
}

// Periodic subtle distortion
function startSubtleDistortion() {
  setInterval(() => {
    if (Math.random() > 0.95) {
      // 5% chance every interval
      triggerMiniJumpscare();
    }
  }, 2000);
}

// Register functions for Lua to call
Events.Subscribe("TriggerJumpscare", triggerJumpscare);
Events.Subscribe("TriggerMiniJumpscare", triggerMiniJumpscare);

// Start subtle effects
startSubtleDistortion();

console.log("Adarknanos UI loaded - Horror mode active");

// ===== OBJECTIVES TRACKER =====

// Configuration
const MAX_OBJECTIVES = 9; // Maximum number of objectives to display
let currentObjectivesCompleted = 0;

// Get the dots container
const objectivesDotsContainer = document.getElementById("objectives-dots");

// Initialize objectives dots
function initializeObjectives() {
  objectivesDotsContainer.innerHTML = ""; // Clear existing dots

  for (let i = 1; i <= MAX_OBJECTIVES; i++) {
    const dot = document.createElement("div");
    dot.className = "objective-dot";
    dot.id = `objective-dot-${i}`;
    dot.textContent = "●"; // Dot character
    objectivesDotsContainer.appendChild(dot);
  }

  console.log(`Initialized ${MAX_OBJECTIVES} objective dots`);
}

// Update objectives display
function updateObjectives(objectivesCompleted) {
  console.log(`Updating objectives: ${objectivesCompleted} completed`);

  const previousCompleted = currentObjectivesCompleted;
  currentObjectivesCompleted = objectivesCompleted;

  // Update dot states
  for (let i = 1; i <= MAX_OBJECTIVES; i++) {
    const dot = document.getElementById(`objective-dot-${i}`);
    if (dot) {
      if (i <= objectivesCompleted) {
        if (!dot.classList.contains("completed")) {
          dot.classList.add("completed");

          // Add a small delay for visual effect when new objective completes
          if (i > previousCompleted) {
            setTimeout(
              () => {
                dot.style.transform = "scale(1.3)";
                setTimeout(() => {
                  dot.style.transform = "scale(1)";
                }, 300);
              },
              (i - previousCompleted - 1) * 100,
            );
          }
        }
      } else {
        dot.classList.remove("completed");
      }
    }
  }
}

// Register event to receive objectives updates from Lua
Events.Subscribe("UpdateObjectivesUI", updateObjectives);

// Initialize on load
initializeObjectives();

// ===== CREDITS SYSTEM =====

const creditsContainer = document.getElementById("credits-container");
const creditsContent = document.getElementById("credits-content");

// Function to roll credits
function rollCredits() {
  console.log("Rolling credits...");

  // Show the credits container
  creditsContainer.classList.add("active");

  // Reset animation by removing and re-adding the content
  creditsContent.style.animation = "none";
  setTimeout(() => {
    creditsContent.style.animation = "roll-credits 30s linear forwards";
  }, 10);

  console.log("Credits started - will complete in 30 seconds");
}

// Register event to receive credits trigger from Lua
Events.Subscribe("RollCredits", rollCredits);

console.log("Credits system initialized");

// ===== PLAYER HUD SYSTEM =====

// Get HUD elements
const healthBar = document.getElementById("health-bar");
const healthText = document.getElementById("health-text");
const ammoClip = document.getElementById("ammo-clip");
const ammoBag = document.getElementById("ammo-bag");
const livesDotsContainer = document.getElementById("lives-dots");

// Lives configuration
const MAX_LIVES = 9;
let currentLives = MAX_LIVES;

// Initialize lives dots
function initializeLives() {
  livesDotsContainer.innerHTML = ""; // Clear existing dots

  for (let i = 1; i <= MAX_LIVES; i++) {
    const dot = document.createElement("div");
    dot.className = "life-dot";
    dot.id = `life-dot-${i}`;
    dot.textContent = "●"; // Dot character
    livesDotsContainer.appendChild(dot);
  }

  console.log(`Initialized ${MAX_LIVES} life dots (no label)`);
}

// Update health display
function updateHealth(currentHealth, maxHealth) {
  const percentage = Math.max(
    0,
    Math.min(100, (currentHealth / maxHealth) * 100),
  );

  // Update bar width
  healthBar.style.width = percentage + "%";

  // Update text
  healthText.textContent = `${Math.round(currentHealth)} / ${Math.round(maxHealth)}`;

  // Add low health warning (below 30%)
  if (percentage <= 30) {
    healthBar.classList.add("low");
  } else {
    healthBar.classList.remove("low");
  }

  console.log(
    `Health updated: ${currentHealth}/${maxHealth} (${percentage.toFixed(1)}%)`,
  );
}

// Update ammo display
function updateAmmo(clipAmmo, bagAmmo) {
  ammoClip.textContent = clipAmmo;
  ammoBag.textContent = bagAmmo;

  console.log(`Ammo updated: ${clipAmmo} / ${bagAmmo}`);
}

// Update lives display
function updateLives(livesRemaining) {
  const previousLives = currentLives;
  currentLives = livesRemaining;

  console.log(`Lives updated: ${currentLives} remaining`);

  // Update dot states
  for (let i = 1; i <= MAX_LIVES; i++) {
    const dot = document.getElementById(`life-dot-${i}`);
    if (dot) {
      if (i <= currentLives) {
        // Life is still alive (show as faded/inactive like objectives)
        dot.classList.remove("lost");
        dot.classList.remove("alive");
      } else {
        // Life is lost (show as red)
        dot.classList.add("lost");
        dot.classList.remove("alive");

        // Add animation effect when life is newly lost
        if (i === currentLives + 1 && currentLives < previousLives) {
          setTimeout(() => {
            dot.style.transform = "scale(1.5)";
            setTimeout(() => {
              dot.style.transform = "scale(1)";
            }, 300);
          }, 50);
        }
      }
    }
  }
}

// Register events to receive updates from Lua
Events.Subscribe("UpdateHealth", updateHealth);
Events.Subscribe("UpdateAmmo", updateAmmo);
Events.Subscribe("UpdateLives", updateLives);

// Initialize lives on load
initializeLives();

console.log("Player HUD system initialized");

