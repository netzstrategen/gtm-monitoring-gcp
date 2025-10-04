1. Create a GCP project with billing enabled (make note of the project ID)
2. Use this repo as a Github template
3. If you want to keep your repo private, create a Github token
4. Run git clone in your terminal to have all files locally
5. Rename terraform.tfvars.example to terraform.tfvars
4. Modify the variables in terraform.tfvars
6. Download gcloud and Terraform CLI if you haven't
7. Authenticate gcloud using `gcloud auth application-default login --project your-project-id`
8. Set the current project to the one you created in step 1. `gcloud config set project project-id`
9. Run Terraform

terraform init
terraform plan
terraform apply
terraform init -migrate-state

10. Copy the IP address in your terminal and add an A record in your DNS settings that points that domain to the IP

10. Import `Google Tag Manager Monitor - Enhanced.tpl` to your web GTM container
11. Configure your GTM Tag monitor tag based on which events + parameters it should track
12. Open Dataform and configure includes/config.js to set which assertion you want to enable and set the relevant config options

13. If you want to destroy the infrastructure, run 
rm backend.tf
terraform init -migrate-state

`terraform destroy`
14. You can also add Slack as a notification channel in GCP

Example:
```js
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
        fields: [
            { 
                name: 'transaction_id',
                threshold: 5  // takes precedence over general "threshold" (optional)
            },
            { 
                name: 'sku',
                threshold: 5  // allow more nulls for sku field
            },
            { 
                name: 'purchase_value',
                threshold: 5
            }
        ]
    },
    low_event_count: {
        // note: if the exclude_time_range end_date is 6:00 and interval is 1 hour,
        // the assertion will check events from 5:00-6:00 - set your end_time accordingly
        enabled: true,
        time_interval: '1 hour',
        timezone: 'Europe/Berlin',
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
                tag_id: '583', 
                min_count: 1,
                status_filter: 'success',
                description: 'HTML - trbo - Sale'
            },
            { 
                tag_id: '644', 
                min_count: 1,
                status_filter: 'success',
                description: 'Awin - Conversion Tag'
            },
            { 
                tag_id: '68', 
                min_count: 1,
                status_filter: 'success',
                description: 'GAds - Conversion - Purchase - with hashed email'
            },
            { 
                tag_id: '576', 
                min_count: 1,
                status_filter: 'success',
                description: 'HTML - Solute - Conversion'
            },
            { 
                tag_id: '438', 
                min_count: 1,
                status_filter: 'success',
                description: 'HTML - Squarelovin'
            },
            { 
                tag_id: '329', 
                min_count: 1,
                status_filter: 'success',
                description: 'Criteo - Purchase - with hashed email'
            },
            { 
                tag_id: '208', 
                min_count: 1,
                status_filter: 'success',
                description: 'Microsoft - Conversion - purchase'
            },
            { 
                tag_id: '563', 
                min_count: 1,
                status_filter: 'success',
                description: 'Microsoft - Conversion - enhanced conv - send hashed email'
            },
            { 
                tag_id: '722', 
                min_count: 1,
                status_filter: 'success',
                description: 'Stape Data Tag - sGTM ad platforms - ecommerce events'
            }
        ]
    }
};

module.exports = {
    EVENT_PARAMS_ARRAY,
    ASSERTIONS
};
```