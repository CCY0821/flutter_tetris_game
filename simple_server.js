const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3000;
const WEB_DIR = path.join(__dirname, 'build', 'web');

// MIME types
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
  '.mp4': 'video/mp4',
  '.woff': 'application/font-woff',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'application/font-otf',
  '.wasm': 'application/wasm'
};

const server = http.createServer((request, response) => {
  const parsedUrl = url.parse(request.url);
  let pathname = parsedUrl.pathname;
  
  // Default to index.html
  if (pathname === '/') {
    pathname = '/index.html';
  }
  
  const fullPath = path.join(WEB_DIR, pathname);
  
  // Security check
  if (!fullPath.startsWith(WEB_DIR)) {
    response.statusCode = 403;
    response.end('Forbidden');
    return;
  }
  
  fs.readFile(fullPath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        response.statusCode = 404;
        response.end(`File not found: ${pathname}`);
      } else {
        response.statusCode = 500;
        response.end(`Server Error: ${error.code}`);
      }
    } else {
      const extname = path.extname(fullPath);
      const contentType = mimeTypes[extname] || 'application/octet-stream';
      
      response.setHeader('Content-Type', contentType);
      response.setHeader('Access-Control-Allow-Origin', '*');
      response.statusCode = 200;
      response.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`🎮 Flutter Tetris Game Server`);
  console.log(`🌐 Server running at http://localhost:${PORT}/`);
  console.log(`📁 Serving files from: ${WEB_DIR}`);
  console.log(`🚀 Marathon Mode Testing Ready!`);
  console.log(`\nPress Ctrl+C to stop the server`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down server gracefully...');
  server.close(() => {
    console.log('✅ Server stopped.');
    process.exit(0);
  });
});