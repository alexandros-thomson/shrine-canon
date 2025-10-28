const fs = require('fs');
const path = require('path');

// Paths
const source = path.join(__dirname, '..', 'docs', 'divine-trinity');
const dest = path.join(__dirname, '..', 'dist');

console.log('🏛️ DIVINE ASSET COPY RITUAL INITIATED');
console.log(`Source: ${source}`);
console.log(`Destination: ${dest}`);

// Ensure dist exists
if (!fs.existsSync(dest)) {
  fs.mkdirSync(dest, { recursive: true });
  console.log('✨ Created dist directory');
}

// Copy asset files (HTML, SVG, JPG, PNG)
let copied = 0;
const files = fs.readdirSync(source);

files.forEach(file => {
  if (file.endsWith('.html') || file.endsWith('.svg') || file.endsWith('.jpg') || file.endsWith('.png')) {
    const srcPath = path.join(source, file);
    const destPath = path.join(dest, file);
    
    // Check if it's a file (not a directory)
    if (fs.statSync(srcPath).isFile()) {
      fs.copyFileSync(srcPath, destPath);
      console.log(`✅ Copied: ${file}`);
      copied++;
    }
  }
});

console.log(`🌟 Divine ritual complete! ${copied} files sanctified.`);