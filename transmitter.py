import cv2
import numpy as np
import time

# =========================================================================
# 1. Configuration & Parameters
# =========================================================================
MESSAGE = "HELLO"       # Message to transmit
F0 = 2.0                # Frequency for bit 0 (Hz)
F1 = 5.0                # Frequency for bit 1 (Hz)
BIT_DURATION = 1.0      # Duration to transmit each bit (seconds)
DELTA_ALPHA = 0.1       # Alpha step (Test both 0.1 and 0.5)
BASE_ALPHA = 0.5        # Baseline transparency level

# Convert message text to binary bit string
binary_message = ''.join(format(ord(c), '08b') for c in MESSAGE)
print(f"Transmitting Message: '{MESSAGE}' -> Bits: {binary_message}")

# =========================================================================
# 2. Generate Base Image
# =========================================================================
# Create a static colorful image/pattern (or load your own image with cv2.imread)
height, width = 600, 800
background = np.zeros((height, width, 3), dtype=np.uint8)
# Fill with a solid color / gradient pattern
background[:, :] = [100, 150, 200] 
cv2.putText(background, "TRANSMITTING...", (200, 300), 
            cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)

# =========================================================================
# 3. BFSK Alpha Modulation Loop
# =========================================================================
cv2.namedWindow("Transmitter Window", cv2.WINDOW_NORMAL)
cv2.resizeWindow("Transmitter Window", width, height)

start_time = time.time()
current_bit_idx = 0

print("Press 'q' in the window to quit transmission.")

while current_bit_idx < len(binary_message):
    elapsed_time = time.time() - start_time
    
    # Determine current bit based on elapsed time per bit
    bit_index = int(elapsed_time // BIT_DURATION)
    
    if bit_index >= len(binary_message):
        print("Transmission Complete!")
        break
        
    current_bit = int(binary_message[bit_index])
    target_freq = F1 if current_bit == 1 else F0
    
    # Square wave alpha modulation formula
    # Toggles alpha above/below BASE_ALPHA at target_freq
    sine_val = np.sin(2 * np.pi * target_freq * elapsed_time)
    alpha = BASE_ALPHA + (DELTA_ALPHA / 2.0) * np.sign(sine_val)
    alpha = np.clip(alpha, 0.0, 1.0)
    
    # Apply alpha modulation brightness adjustment to frame
    frame = (background * alpha).astype(np.uint8)
    
    # Visual status overlay for monitoring
    cv2.putText(frame, f"Bit {bit_index+1}/{len(binary_message)}: '{current_bit}' @ {target_freq}Hz", 
                (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
    
    cv2.imshow("Transmitter Window", frame)
    
    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()