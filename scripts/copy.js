const fs = require('fs-extra');
const path = require('path');

// Sanctify divine trinity files
const source = path.join('docs', 'divine-trinity');
const dest = 'dist';

(async () => {
  try {
    // Check if source directory exists
    if (!await fs.pathExists(source)) {
      console.error(`❌ Source directory not found: ${source}`);
      process.exit(1);
    }

    // Copy HTML and SVG files
    await fs.ensureDir(dest);
    const files = await fs.readdir(source);
    
    for (const file of files) {
      if (file.endsWith('.html') || file.endsWith('.svg')) {
        await fs.copyFile(path.join(source, file), path.join(dest, file));
      }
    }

    console.log('✨ Divine assets copied to dist!');
  } catch (error) {
    console.error('❌ Error copying divine assets:', error.message);
    process.exit(1);
  }
})();
