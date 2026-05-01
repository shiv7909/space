#!/usr/bin/env node
/**
 * Generate notification icons using Node.js
 * Install: npm install canvas
 */
const fs = require('fs');
const path = require('path');

// If canvas is not installed, provide installation instructions
try {
  const canvas = require('canvas');
} catch (e) {
  console.log('📦 Installing canvas package...');
  require('child_process').execSync('npm install canvas', { stdio: 'inherit' });
}

const { createCanvas } = require('canvas');

function createNotificationIcon(size) {
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext('2d');

  // Draw black circle background
  ctx.fillStyle = '#000000';
  const margin = size * 0.08;
  ctx.beginPath();
  ctx.arc(size / 2, size / 2, size / 2 - margin, 0, Math.PI * 2);
  ctx.fill();

  // Draw white "S"
  ctx.fillStyle = '#FFFFFF';
  ctx.font = `bold ${Math.floor(size * 0.65)}px Arial`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('S', size / 2, size / 2);

  return canvas;
}

const densities = {
  'drawable-mdpi': 48,
  'drawable-hdpi': 72,
  'drawable-xhdpi': 96,
  'drawable-xxhdpi': 144,
  'drawable-xxxhdpi': 192,
};

console.log('🎨 Generating notification icons...\n');

Object.entries(densities).forEach(([density, size]) => {
  const dir = path.join('D:\\habitz\\android\\app\\src\\main\\res', density);

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const canvas = createNotificationIcon(size);
  const buffer = canvas.toBuffer('image/png');
  const filePath = path.join(dir, 'ic_notification.png');

  fs.writeFileSync(filePath, buffer);
  console.log(`✅ ${density}: ${size}x${size} -> ${filePath}`);
});

console.log('\n✅ All notification icons generated successfully!');
console.log('📱 Run: flutter clean && flutter pub get && flutter run\n');

