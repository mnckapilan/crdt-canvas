var http = require('http');

var versions_server = http.createServer((request, response) => {
  response.end('Hello there! The Node JS server is running');
});
versions_server.listen(3000);
