const http = require('http');
var express = require('express');

const requestListener = function (req, res) {
  //var obj = JSON.parse(req)
  res.writeHead(200);
  res.end('Hello, World!');
}

const server = http.createServer(requestListener);
server.listen(8080);
