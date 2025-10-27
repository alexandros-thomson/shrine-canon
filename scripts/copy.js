const fs = require('fs-extra');
const path = require('path');

// Sanctify divine trinity files
const source = path.join('docs', 'divine-trinity');
const dest = 'dist';

// Copy HTML and SVG files
fs.ensureDirSync(dest);
const files = fs.readdirSync(source);
files.forEach(file => {
  if (file.endsWith('.html') || file.endsWith('.svg')) {
    fs.copyFileSync(path.join(source, file), path.join(dest, file));
  }
});

console.log('✨ Divine assets copied to dist!');
