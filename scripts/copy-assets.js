const fs = require('fs');
const path = require('path');

const source = 'docs/divine-trinity';
const dest = 'dist';

// Ensure dist exists
if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });

// Copy HTML and SVG files
fs.readdirSync(source).forEach(file => {
  if (file.endsWith('.html') || file.endsWith('.svg')) {
    fs.copyFileSync(
      path.join(source, file),
      path.join(dest, file)
    );
    console.log(`✨ Copied: ${file}`);
  }
});