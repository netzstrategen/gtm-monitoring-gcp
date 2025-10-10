# GTM Tag Monitoring on GCP

A comprehensive solution for monitoring Google Tag Manager (GTM) tag firing with automated alerting using Google Cloud Platform, Terraform, and Dataform.

## Overview

This project provides an end-to-end infrastructure for monitoring GTM tag execution, storing event data in BigQuery, running automated assertions on the data, and sending alerts when issues are detected. The system captures GTM tag firing events from your website and validates them against configurable thresholds and conditions.

## Architecture

```mermaid
graph TB
    subgraph "Website"
        GTM[GTM Container<br/>with Monitor Tag]
    end
    
    subgraph "GCP Infrastructure"
        LB[Global Load Balancer<br/>+ SSL Certificate]
        GCS[Cloud Storage<br/>collect.html endpoint]
        Logs[Cloud Logging<br/>Log Sink]
        
        subgraph "BigQuery Dataset"
            LogView[_AllLogs<br/>Log View]
            Staging[stg_gtm_tag_logs<br/>Staging Table]
            AssertionLogs[assertion_logs<br/>All Assertion Results]
        end
        
        subgraph "Dataform"
            DF_Repo[Dataform Repository<br/>GitHub Connection]
            DF_Release[Release Config<br/>Compiles Dataform]
            DF_Workflow[Workflow Config<br/>Runs Dataform]
            DF_Assert[Assertion Queries<br/>- Non-null checks<br/>- Event count validation<br/>- Tag failure detection<br/>- Tag count monitoring]
        end
        
        subgraph "Monitoring & Alerting"
            ErrorBucket[Error Log Bucket<br/>Filtered Logs]
            AlertPolicy[Alert Policy<br/>Log-based Monitoring]
            NotifChannel[Notification Channels<br/>Email Alerts]
        end
    end
    
    GTM -->|POST /collect| LB
    LB --> GCS
    GCS -->|Structured Logs| Logs
    Logs -->|Linked Dataset| LogView
    
    DF_Repo --> DF_Release
    DF_Release -->|Triggers| DF_Workflow
    DF_Workflow -->|Reads| LogView
    DF_Workflow -->|Materializes| Staging
    Staging -->|Input for| DF_Assert
    
    DF_Assert -->|Failed Assertions| ErrorBucket
    DF_Assert -->|Materializes| AssertionLogs
    ErrorBucket -->|Triggers| AlertPolicy
    AlertPolicy -->|Sends| NotifChannel
```

### Project Structure

```
gtm-tag-monitoring-gcp/
├── definitions/                  # Dataform SQL definitions
│   ├── 00_sources/              # Source declarations
│   │   └── declarations.js      # BigQuery log view source
│   ├── 01_staging/              # Data transformation layer
│   │   └── gtm_events.sqlx      # Parse and structure GTM events
│   └── 02_assertions/           # Data quality checks
│       ├── non_null.sqlx        # Validate required parameters
│       ├── low_event_count.sqlx # Monitor event volumes
│       ├── tag_failure.sqlx     # Detect tag failures
│       └── low_tag_count.sqlx   # Monitor tag firing rates
├── includes/                     # Dataform configuration files
│   ├── config.js                # Assertion configuration
│   └── helpers.js               # Shared utility functions
├── terraform/                    # Infrastructure as Code
│   ├── alerting.tf              # Alert policies and notifications
│   ├── apis.tf                  # Enable required GCP APIs
│   ├── dataform.tf              # Dataform repository setup
│   ├── load_balancer.tf         # HTTPS load balancer config
│   ├── locals.tf                # Local variables
│   ├── logging.tf               # Log sinks and buckets
│   ├── outputs.tf               # Terraform outputs
│   ├── providers.tf             # Provider configuration
│   ├── remote_backend.tf        # GCS backend for state
│   ├── storage.tf               # Cloud Storage bucket
│   ├── variables.tf             # Variable declarations
│   └── terraform.tfvars.example # Example configuration
├── Google Tag Manager Monitor - Enhanced.tpl  # GTM tag template
├── workflow_settings.yaml        # Dataform project settings
├── .gitignore
├── LICENSE
└── README.md
```

## Components

### 1. GTM Monitor Tag
- Custom GTM tag template that sends the event and tag metadata to the custom endpoint
- Can be configured to send event parameters (beyond the regular tag metadata)
- `eventName` field can be optionally overwritten (GTM dataLayer event name is used by default)

### 2. Infrastructure (Terraform)
- **Load Balancer**: Global HTTPS load balancer with custom domain support (GCS as backend)
- **Cloud Storage**: Serves a minimal HTML endpoint that receives GTM events
- **Cloud Logging**: Captures and structures incoming requests as logs
- **BigQuery**: Log view for querying the raw logs
- **Dataform**: Automated SQL transformations and data quality assertions
- **Cloud Monitoring**: Alert policies and notification channels

### 3. Data Pipeline (Dataform)
- **Source Layer** (`00_sources`): Declares the BigQuery log view as a source
- **Staging Layer** (`01_staging`): Transforms raw logs into a structured table where each row is an executed tag
- **Assertion Layer** (`02_assertions`): Runs data quality checks with configurable thresholds

## Features

### Monitoring Capabilities
- ✅ **Tag Success/Failure Tracking**: Monitor which tags fired successfully or failed
- ✅ **Parameter Non-null Check**: Ensure required parameters are present and non-null
- ✅ **Event Volume Monitoring**: Alert on abnormally low event counts
- ✅ **Tag Volume Monitoring**: Alert when specific tags fire below expected thresholds
- ✅ **Custom Threshold Configuration**: Set different thresholds per event, parameter, or tag
- ✅ **Time-based Exclusions**: Skip monitoring during specified time ranges (e.g., overnight)


## Prerequisites

- Google Cloud Platform account with billing enabled
- GitHub account (for Dataform repository connection)
- The ability to create an A record in your site's DNS settings

### Required Tools
- [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install)
- [Terraform CLI](https://developer.hashicorp.com/terraform/install)
- Git

## Setup Instructions

### 1. GCP Project Setup

Create a new GCP project with billing enabled and note the project ID.

```bash
gcloud projects create YOUR_PROJECT_ID
gcloud billing projects link YOUR_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT_ID
```

### 2. Repository Setup

Use this repository as a GitHub template, or clone it directly:

```bash
git clone https://github.com/datatovalue/gtm-tag-monitoring-gcp.git
```

**For private repositories**: Create a [GitHub Personal Access Token](https://github.com/settings/personal-access-tokens) with these permissions:

- Administration (Read and write)
- Commit statuses (Read-only)
- Contents (Read and write)
- Deployments (Read-only)

This token is used as a Secret in GCP to connect your private Github repo with your Dataform repo.

### 3. Configure Terraform Variables

Rename the example variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` at will.

### 4. Configure Dataform Settings

Edit `workflow_settings.yaml`:

```yaml
defaultProject: your-project-id
defaultLocation: your-region
defaultDataset: dataform
defaultAssertionDataset: assertions
dataformCoreVersion: 3.0.0
```

Use the same region you configured in `terraform.tfvars`!

### 5. Authenticate and Initialize

```bash
# Authenticate with GCP and set active project
gcloud auth application-default login --project your-project-id

# Initialize Terraform (make sure that you are in the terraform folder)
terraform init
```

### 6. Deploy Infrastructure

```bash
# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply

# Migrate state to remote backend (created during apply)
terraform init -migrate-state
```

**Important**: After the first `terraform apply`, the remote backend (GCS bucket) is created. Running `terraform init -migrate-state` moves your state file to this remote backend for better collaboration and safety.
If you do not wish to use GCS as a remote backend, feel free to remove `remote_backend.tf` before running `terraform apply` or remove `remote_backend.tf` and `backend.tf` if you already deployed.
After deleting the backend files, running `terraform init -migrate-state` will move your state back to local.

### 7. DNS Configuration

After deployment, Terraform outputs the load balancer IP address. Create an A record in your DNS settings:

```
Record Type: A
Name: monitor (or your chosen subdomain)
Value: [IP address from terraform output]
TTL: 300
```

Wait for DNS propagation (can take up to 48 hours, typically much faster).

### 8. GTM Configuration

1. Import `Google Tag Manager Monitor - Enhanced.tpl` to your web GTM container:
   - In GTM, go to **Templates** → **Tag Templates** → **New**
   - Click the menu (⋮) → **Import**
   - Select the `.tpl` file from this repository

2. Create a new tag using the imported template

3. Configure the monitoring tag:
   - **Endpoint**: `https://monitor.yourdomain.com/tag`
   - **Optionally Overwrite Event Name**: `eventName` field can be optionally overwritten (GTM dataLayer event name is used by default). Useful if you want to monitor a `gtm.triggerGroup` or any other non-descriptive dataLayer event.
   - **Additional Parameters**: Define custom event parameters to track (could be for monitoring or to provide additional context when another parameter is monitored).

4. Set the trigger to fire on all GTM events that you want to monitor. I recommend starting with conversion events and slowly upscaling if needed.

6. For all tags you want to monitor, toggle `Include tag name` in Advanced Settings → Additional Tag Metadata and set `name` as the `Key for tag name`. Otherwise only tag IDs will be sent.

7. **Important**: In the GTM monitor tag's Advanced Settings → Additional Tag Metadata:
   - Add `exclude=true` key value pair to the GTM Monitor tag itself to prevent self-tracking

8. Test the setup in debug view and inspect the Network tab to see if a request has been dispatched to your custom endpoint (and returns a 200 status code).

9. If all is well, publish the container!

### 9. Configure Dataform

1. Open the Dataform repository
2. Create a new workspace
3. Edit `includes/config.js` to configure your assertions:

```javascript
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
        threshold: 5,
        fields: [
            { name: 'transaction_id', threshold: 5 },
            { name: 'sku', threshold: 5 },
            { name: 'purchase_value', threshold: 5 }
        ]
    },
    low_event_count: {
        enabled: true,
        time_interval: '1 hour',
        timezone: 'Europe/Berlin',
        exclude_time_ranges: [
            { start_time: '23:00:00', end_time: '08:00:00' }
        ],
        thresholds: [
            { event_name: 'place-order', min_count: 1 }
        ]
    },
    tag_failure: {
        enabled: true,
        time_interval: '15 minute',
        threshold: 2,
        exclude_tag_ids: ['68', '563', '208']
    },
    low_tag_count: {
        enabled: true,
        time_interval: '1 hour',
        timezone: 'Europe/Berlin',
        exclude_time_ranges: [
            { start_time: '23:00:00', end_time: '08:00:00' }
        ],
        thresholds: [
            { tag_id: '529', min_count: 1, status_filter: 'success', description: 'GA4 - purchase' },
            { tag_id: '170', min_count: 1, status_filter: 'success', description: 'Floodlight - Sales' },
            { tag_id: '68', min_count: 1, status_filter: 'success', description: 'GAds - Conversion' }
        ]
    }
};

module.exports = {
    EVENT_PARAMS_ARRAY,
    ASSERTIONS
};
```

- Use `alias` to rename an event parameter.
- You can enable/disable data quality checks with the `enabled` flag.
- Use `time_interval` field to return a valid [INTERVAL object](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#interval_type). It sets the amount of time (compared to when the Dataform workflow runs) that should be used for the data quality check.
- Use `threshold(s)` to allow a certain number of failures. Its format differs per data quality check.
- Use `timezone` and `exclude_time_ranges` together to exclude certain time intervals for the `low_tag_count` and `low_event_count` checks. Useful for excluding overnight periods.


4. Commit and push your changes.

5. Wait for the next Dataform workflow to trigger or run the actions manually.

### 10. Optional: Add Slack Notifications Manually

You can manually add Slack as a notification channel in GCP:

1. Go to **Monitoring** → **Alerting** → **Edit Notification Channels**
2. Add **Slack** and authenticate with your workspace
3. Edit the alert policy to include the Slack channel

## Cost Considerations

### Monthly Cost Breakdown

1. **Cloud Storage**: 2 small files so essentially free
2. **BigQuery**: Query processing: $5-6/TB processed (not likely to be substantial)
3. **Cloud Logging**:
   - First 50 GB/month: Free
   - Additional data: $0.50/GB
   - Typical monthly cost: $0-2 for most sites
4. **Load Balancer**:
   - Global forwarding rule: ~$18/month (fixed cost)
   - Data processing: $0.008-0.012/GB
   - Typical monthly cost: $20-25
5. **Cloud Monitoring**: Usually free within GCP free tier limits
6. **Dataform**: Free (part of BigQuery)

**Note**: The load balancer forwarding rule is the primary fixed cost. All other costs scale with usage.



## Destroying the Infrastructure

### Option 1: Delete the Entire Project

The simplest approach - deletes everything including all resources:

```bash
gcloud projects delete YOUR_PROJECT_ID
```

### Option 2: Terraform Destroy

To remove only Terraform-managed resources:

```bash
# Remove remote backend configuration
rm terraform/backend.tf

# Migrate state back to local
terraform init -migrate-state

# Delete all Dataform workspaces manually in GCP Console first

# Destroy infrastructure
terraform destroy
```

**Important**: Delete Dataform workspaces manually before running `terraform destroy` to avoid dependency issues.



## Advanced Configuration

### Custom Event Parameters

Add custom parameters to track in `includes/config.js`:

```javascript
const EVENT_PARAMS_ARRAY = [
    { name: 'value', alias: 'purchase_value' },
    { name: 'currency' },
    { name: 'user_id', alias: 'uid' },
    { name: 'session_id' }
];
```

The `alias` field allows you to rename parameters in BigQuery for better readability.

### Assertion Types

#### 1. Non-Null Assertion
Validates that critical event parameters are not null or missing.

```javascript
non_null: {
    enabled: true,
    time_interval: '15 minute',
    threshold: 5,  // allow up to 5 null values before failing
    fields: [
        { name: 'transaction_id', threshold: 5 },
        { name: 'sku', threshold: 5 },
        { name: 'purchase_value', threshold: 5 }
    ]
}
```

#### 2. Low Event Count Assertion
Ensures minimum event volumes are maintained within specified time intervals.

```javascript
low_event_count: {
    enabled: true,
    time_interval: '1 hour',
    timezone: 'Europe/Berlin',
    exclude_time_ranges: [
        { start_time: '23:00:00', end_time: '08:00:00' }
    ],
    thresholds: [
        { event_name: 'place-order', min_count: 1 }
    ]
}
```

#### 3. Tag Failure Assertion
Detects when tags fail to fire successfully.

```javascript
tag_failure: {
    enabled: true,
    time_interval: '15 minute',
    threshold: 2,  // allow up to 2 failures before alerting
    exclude_tag_ids: ['68', '563', '208']  // exclude specific tags
}
```

#### 4. Low Tag Count Assertion
Monitors that specific tags fire at expected volumes.

```javascript
low_tag_count: {
    enabled: true,
    time_interval: '1 hour',
    timezone: 'Europe/Berlin',
    exclude_time_ranges: [
        { start_time: '23:00:00', end_time: '08:00:00' }
    ],
    thresholds: [
        { 
            tag_id: '529', 
            min_count: 1,
            status_filter: 'success',
            description: 'GA4 - purchase'
        }
    ]
}
```

### Time-based Exclusions

Configure exclusions for periods with expected low traffic:

```javascript
exclude_time_ranges: [
    { start_time: '23:00:00', end_time: '08:00:00' },  // Overnight
    { start_time: '01:00:00', end_time: '06:00:00' }   // Early morning
]
```

**Important**: If the `end_time` is 6:00 and `time_interval` is 1 hour, the assertion checks events from 5:00-6:00. Set your `end_time` accordingly.

### Multiple Notification Channels

Add multiple email recipients or different notification types:

```hcl
notification_users = [
  { name = "Analytics Team", email = "analytics@company.com" },
  { name = "Dev Team", email = "dev@company.com" },
  { name = "On-Call", email = "oncall@company.com" }
]
```

## Security Considerations

1. **GitHub Token**: Store as a secret, never commit to repository
2. **Service Accounts**: Follow principle of least privilege
3. **Domain Access**: Ensure only your domain can send to the collection endpoint (configure CORS if needed)
4. **Log Retention**: Set appropriate retention periods to comply with data privacy regulations
5. **PII Data**: Avoid sending personally identifiable information through GTM monitoring

## License

This project is licensed under the GNU GPL v3.0 License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions email me at [krisztian@datatovalue.com](mailto:krisztian@datatovalue.com)
