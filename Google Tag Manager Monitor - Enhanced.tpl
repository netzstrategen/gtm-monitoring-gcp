___INFO___

{
  "displayName": "Google Tag Manager Monitor - Enhanced",
  "description": "A template for setting up tag monitoring in Google Tag Manager.",
  "__wm": "VGVtcGxhdGUtQXV0aG9yX0dvb2dsZS1UYWctTWFuYWdlci1Nb25pdG9yLVNpbW8tQWhhdmE\u003d",
  "securityGroups": [],
  "id": "cvt_temp_public_id",
  "type": "TAG",
  "version": 1,
  "brand": {
    "displayName": "",
    "id": "brand_dummy"
  },
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "help": "Provide the URL to which the GET request with tag data is sent.",
    "alwaysInSummary": true,
    "displayName": "GET request endpoint",
    "simpleValueType": true,
    "name": "endPoint",
    "type": "TEXT",
    "valueHint": "e.g. https://track.com/collect"
  },
  {
    "help": "If you select \u003cstrong\u003eNo\u003c/strong\u003e, details of all the tags that fired for any given hit are sent in a single GET request. If you select \u003cstrong\u003eYes\u003c/strong\u003e, you can choose the maximum number of tags per request, and the tag will automatically send multiple requests if necessary.",
    "displayName": "Batch hits",
    "simpleValueType": true,
    "name": "batchHits",
    "type": "RADIO",
    "radioItems": [
      {
        "displayValue": "No",
        "value": "no"
      },
      {
        "displayValue": "Yes",
        "help": "",
        "value": "yes",
        "subParams": [
          {
            "help": "Enter the maximum number of tags per request that will be dispatched to the endpoint. If necessary, multiple requests will be made.",
            "valueValidators": [
              {
                "type": "POSITIVE_NUMBER"
              }
            ],
            "displayName": "Maximum number of tags per request",
            "defaultValue": 10,
            "simpleValueType": true,
            "name": "maxTags",
            "type": "TEXT"
          }
        ]
      }
    ]
  },
  {
    "help": "Provide a variable that should be used as the eventName (instead of the GTM trigger event)",
    "alwaysInSummary": true,
    "displayName": "Override eventName parameter (Optional)",
    "simpleValueType": true,
    "name": "eventName",
    "type": "TEXT",
    "valueHint": "{{New eventName}}"
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "additionalParams",
    "displayName": "Additional parameters (Optional)",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Key",
        "name": "key",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "value",
        "type": "TEXT"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

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


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "event"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_metadata",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 11/07/2019, 09:11:59


