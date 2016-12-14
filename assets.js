var express = require('express');
var fs = require('fs');

var router = express.Router();
var content = fs.readFileSync('.hyperdev-assets', 'utf8');

// Example url
// https://s3.amazonaws.com/hyperweb-editor-assets/us-east-1%3Ad0d03a8e-22bf-451d-ba15-f08d8f4e99ba%2Fclick-for-details.svg

// For some reason the .hyperdev-assets file is not parseable by JSON.parse :|
router.get('/:name', function (request, response) {
  var name = '%2F' + request.params.name + '"';
  var index = content.indexOf(name);
  if (index < 0) {
    return response.sendStatus(404);
  }
  var startIndex = index - 1;
  while (startIndex >= 0) {
    if (content[startIndex] === '"') {
      break;
    }
    startIndex -= 1;
  }
  if (startIndex === 0) {
    return response.sendStatus(503);
  }
  startIndex += 1;
  var endIndex = index + name.length - 1;
  var url = content.substring(startIndex, endIndex);
  return response.redirect(url);
});

module.exports = router;