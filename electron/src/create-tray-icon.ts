import { nativeImage } from 'electron';

export function createTrayIcon(): Electron.NativeImage {
  // Create a simple bitmap icon that works reliably on macOS
  const size = 16;
  const canvas = Buffer.alloc(size * size * 4); // RGBA buffer
  
  // Fill with a simple pattern - create a circle with "P" inside
  for (let x = 0; x < size; x++) {
    for (let y = 0; y < size; y++) {
      const index = (y * size + x) * 4;
      const centerX = size / 2;
      const centerY = size / 2;
      const distance = Math.sqrt((x - centerX) ** 2 + (y - centerY) ** 2);
      
      if (distance <= 6) {
        // Inside circle - blue background
        canvas[index] = 102;     // R
        canvas[index + 1] = 126; // G
        canvas[index + 2] = 234; // B
        canvas[index + 3] = 255; // A
      } else {
        // Outside circle - transparent
        canvas[index] = 0;       // R
        canvas[index + 1] = 0;   // G
        canvas[index + 2] = 0;   // B
        canvas[index + 3] = 0;   // A
      }
    }
  }
  
  // Create image from buffer
  const image = nativeImage.createFromBuffer(canvas, { width: size, height: size });
  return image.resize({ width: 16, height: 16 });
} 