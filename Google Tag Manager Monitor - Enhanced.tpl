// Require the necessary APIs
const addEventCallback = require('addEventCallback');
const readFromDataLayer = require('copyFromDataLayer');
const sendPixel = require('sendPixel');
const getTimestamp = require('getTimestamp');
const makeString = require('makeString');
const encodeUriComponent = require('encodeUriComponent');
const makeTableMap = require('makeTableMap');

// Get the dataLayer event that triggered the tag
const event = data.eventName || readFromDataLayer('event');

// Add a timestamp to separate events named the same way from each other
const eventTimestamp = getTimestamp();
const endPoint = data.endPoint;
const batchHits = data.batchHits === 'yes';
const maxTags = data.maxTags;

// Create a map for custom variables from the additionalParams table
const customVarsMap = makeTableMap(data.additionalParams, 'key', 'value') || {};

// Utility for splitting an array into multiple arrays of given size
const splitToBatches = (arr, size) => {
  const newArr = [];
  for (let i = 0, len = arr.length; i < len; i += size) {
    newArr.push(arr.slice(i, i + size));
  }
  return newArr;
};

// Function to safely handle values for URL parameters
const formatValue = (value) => {
  if (value === undefined || value === null) {
    return '';
  }
  // Make sure the value is a string and encode it for URL
  return encodeUriComponent(makeString(value));
};

// The addEventCallback gets two arguments: container ID and a data object with an array of tags that fired
addEventCallback((ctid, eventData) => {
  // Filter out the monitoring tag itself
  const tags = eventData.tags.filter(t => t.exclude !== 'true');
  
  // If batching is enabled, split the tags into batches of the given size
  const batches = batchHits ? splitToBatches(tags, maxTags) : [tags];
  
  // For each batch, build a payload and dispatch to the endpoint as a GET request
  batches.forEach(tags => {
    let payload = '?eventName=' + formatValue(event) + '&eventTimestamp=' + formatValue(eventTimestamp);
    
    // Add custom variables to the payload from additionalParams
    for (const key in customVarsMap) {
      if (key && customVarsMap[key] !== undefined) {
        payload += '&' + formatValue(key) + '=' + formatValue(customVarsMap[key]);
      }
    }
    
    tags.forEach((tag, idx) => {
      const tagPrefix = '&tag' + (idx + 1);
      payload +=
        tagPrefix + 'id=' + formatValue(tag.id) +
        tagPrefix + 'nm=' + formatValue(tag.name) +
        tagPrefix + 'st=' + formatValue(tag.status) +
        tagPrefix + 'et=' + formatValue(tag.executionTime);
    });
    
    sendPixel(endPoint + payload, null, null);
  });
});

// After adding the callback, signal tag completion
data.gtmOnSuccess();