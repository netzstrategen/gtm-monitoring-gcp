const urlDecodeSQL = (urlColumnName) => {
    return `
  (
  SELECT SAFE_CONVERT_BYTES_TO_STRING(
    ARRAY_TO_STRING(ARRAY_AGG(
        IF(STARTS_WITH(y, '%'), FROM_HEX(SUBSTR(y, 2)), CAST(y AS BYTES)) ORDER BY i
      ), b''))
  FROM UNNEST(REGEXP_EXTRACT_ALL(${urlColumnName}, r"%[0-9a-fA-F]{2}|[^%]+")) AS y WITH OFFSET AS i
  )`
};



const extractFromURL = (paramName, alias) => {
  // If no alias provided, use the parameter name as alias
  const columnAlias = alias || paramName;
  return `regexp_extract(decoded_url, r"${paramName}=([^&]+)") as ${columnAlias}`;
};



function generateNonNullAssertionsWithCounts(tableName, config) {
  const fields = config.fields || [];
  const globalThreshold = config.threshold || 0;
  
  if (!fields || fields.length === 0) {
    throw new Error('Fields array cannot be empty in non_null assertion config');
  }
  
  // Get time interval from config
  const timeInterval = config.time_interval || '15 minute';
  
  const unionQueries = fields.map(field => {
    const fieldInterval = field.time_interval || timeInterval;
    const fieldThreshold = field.threshold !== undefined ? field.threshold : globalThreshold;
    
    return `
    select 
      '${field.name}' as field_name,
      count(distinct event_id) as null_count,
      ${fieldThreshold} as threshold,
      '${field.name} is null' as failing_row_condition,
      case 
        when count(distinct event_id) > ${fieldThreshold} then 'fail'
        else 'pass'
      end as status
    from ${tableName}
    where ${field.name} is null
      and timestamp >= timestamp_sub(current_timestamp(), interval ${fieldInterval})`;
  });
  
  // Return all fields (including those with 0 nulls for complete reporting)
  return `
    select 
      field_name,
      null_count,
      threshold,
      failing_row_condition,
      status
    from (
      ${unionQueries.join('\n union all \n')}
    )`;
}

function generateEventCountQueryWithThresholds(tableRef, config) {
    const interval = config.time_interval || "1 hour";
    const thresholds = config.thresholds || [];
    
    if (thresholds.length === 0) {
        return "select 0 as event_count, 'no_thresholds_configured' as event_name, 0 as expected_count, 'unknown' as status";
    }
    
    const queries = thresholds.map(threshold => {
        return `
        select 
            '${threshold.event_name}' as event_name,
            coalesce(actual_count, 0) as event_count,
            ${threshold.min_count} as expected_count,
            case 
                when coalesce(actual_count, 0) >= ${threshold.min_count} then 'pass'
                else 'fail'
            end as status,
            case 
                when coalesce(actual_count, 0) = 0 then 'no_events_found'
                when coalesce(actual_count, 0) < ${threshold.min_count} then 'below_threshold'
                else 'above_threshold'
            end as failure_reason
        from (
            select count(*) as actual_count
            from ${tableRef}
            where event_name = '${threshold.event_name}'
                and timestamp >= timestamp_sub(current_timestamp(), interval ${interval})
                -- NO time exclusion filters here since we skip the assertion entirely
        )`;
    });
    
    return queries.join('\n    union all\n');
}

// Version without time exclusion filters for tags (for use with skip logic)
function generateTagCountQueryWithThresholds(tableRef, config) {
    const interval = config.time_interval || "1 hour";
    const thresholds = config.thresholds || [];
    
    if (thresholds.length === 0) {
        return "select 0 as tag_count, 'no_thresholds_configured' as tag_id, '' as description, 0 as expected_count, 'unknown' as status";
    }
    
    const queries = thresholds.map(threshold => {
        const statusFilter = threshold.status_filter 
            ? `and tag_status = '${threshold.status_filter}'`
            : '';
            
        return `
        select 
            '${threshold.tag_id}' as tag_id,
            '${threshold.description || threshold.tag_id}' as description,
            coalesce(actual_count, 0) as tag_count,
            ${threshold.min_count} as expected_count,
            '${threshold.status_filter || 'all'}' as status_filter,
            case 
                when coalesce(actual_count, 0) >= ${threshold.min_count} then 'pass'
                else 'fail'
            end as status,
            case 
                when coalesce(actual_count, 0) = 0 then 'no_tags_found'
                when coalesce(actual_count, 0) < ${threshold.min_count} then 'below_threshold'
                else 'above_threshold'
            end as failure_reason
        from (
            select count(*) as actual_count
            from ${tableRef}
            where tag_id = '${threshold.tag_id}'
                and timestamp >= timestamp_sub(current_timestamp(), interval ${interval})
                ${statusFilter}
                -- NO time exclusion filters here since we skip the assertion entirely
        )`;
    });
    
    return queries.join('\n    union all\n');
}

module.exports = {
    urlDecodeSQL,
    extractFromURL,
    generateNonNullAssertionsWithCounts,
    generateEventCountQueryWithThresholds,
    generateTagCountQueryWithThresholds
};