const EVENT_PARAMS_ARRAY = [
    { name: 'value', alias: 'purchase_value' },
    { name: 't_id', alias: 'transaction_id' },
    { name: 'consent' },
    { name: 'sku' },
    { name: 'path' }
];

const ASSERTIONS = {
    non_null: {
        enabled: true,
        time_interval: '15 minute',
        threshold: 5,  // allow up to 5 null values before failing
        event_filter: [], // applies event filter to all fields (optional)
        fields: [
            { 
                name: 'transaction_id',
                threshold: 5,  // field-specific threshold (optional)
                event_filter: 'purchase' // takes precedence over global (optional)
            },
            { 
                name: 'sku',
                threshold: 7,  // allow more nulls for sku field
                event_filter: ['view_item', 'add_to_cart', 'purchase']
            },
            { 
                name: 'purchase_value',
                threshold: 5,
                event_filter: 'purchase'
            },
            { 
                name: 'path',
                threshold: 5
                // checks all events
            }
        ]
    },
    low_event_count: {
        // note: if the exclude_time_range end_date is 6:00 and interval is 1 hour,
        // the assertion will check events from 5:00-6:00 - set your end_time accordingly
        enabled: true,
        time_interval: '1 hour',
        timezone: 'Europe/Berlin',
        exclude_days: [1, 7],  // Exclude Sunday (1) and Saturday (7)
        exclude_time_ranges: [
            { start_time: '23:00:00', end_time: '08:00:00' }  // 11PM-8AM overnight exclusion
        ],
        thresholds: [
            { event_name: 'place-order', min_count: 1 }
        ]
    },
    tag_failure: {
        enabled: true,
        time_interval: '15 minute',
        threshold: 2,
        exclude_tag_ids: ['68','563','208']
    },
    low_tag_count: {
        // note: if the exclude_time_range end_date is 6:00 and interval is 1 hour,
        // the assertion will check events from 5:00-6:00 - set your end_time accordingly
        enabled: true,
        time_interval: '1 hour',
        timezone: 'Europe/Berlin',
        exclude_days: [1, 7],  // Exclude Sunday (1) and Saturday (7)
        exclude_time_ranges: [
            { start_time: '23:00:00', end_time: '08:00:00' }  // same overnight exclusion
        ],
        thresholds: [
            { 
                tag_id: '529', 
                min_count: 1,
                status_filter: 'success',
                description: 'GA4 - purchase'
            },
            { 
                tag_id: '170', 
                min_count: 1,
                status_filter: 'success',
                description: 'Floodlight - Sales - Purchase'
            },
            { 
                tag_id: '68', 
                min_count: 1,
                status_filter: 'success',
                description: 'GAds - Conversion - Purchase'
            },
            { 
                tag_id: '208', 
                min_count: 1,
                status_filter: 'success',
                description: 'Microsoft - Conversion - purchase'
            }
        ]
    }
};

module.exports = {
    EVENT_PARAMS_ARRAY,
    ASSERTIONS
};