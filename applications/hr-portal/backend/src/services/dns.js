const { Route53Client, ChangeResourceRecordSetsCommand, ListResourceRecordSetsCommand } = require('@aws-sdk/client-route-53');
const logger = require('../utils/logger');

// Initialize Route53 client
const route53 = new Route53Client({ region: process.env.AWS_REGION || 'eu-west-1' });

// Configuration
const HOSTED_ZONE_ID = process.env.ROUTE53_HOSTED_ZONE_ID || 'Z0206991D2VAV0U5DTHR';
const DOMAIN = process.env.WORKSPACE_DOMAIN || 'innovatech.local';

/**
 * Generate a personal DNS name from employee data
 * Format: firstname.lastname.innovatech.local
 */
function generateDnsName(employee) {
  const firstName = sanitizeDnsLabel(employee.firstName);
  const lastName = sanitizeDnsLabel(employee.lastName);
  return `${firstName}.${lastName}.${DOMAIN}`;
}

/**
 * Sanitize a string for use as DNS label
 * DNS labels can only contain a-z, 0-9, and hyphens
 */
function sanitizeDnsLabel(str) {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[^a-z0-9]/g, '')       // Remove non-alphanumeric
    .substring(0, 63);               // DNS label max 63 chars
}

/**
 * Create DNS A record pointing to EKS node IP
 * @param {object} employee - Employee data
 * @param {string} nodeIp - IP address of the EKS node running the workspace
 * @param {number} nodePort - NodePort for the workspace service
 * @returns {object} DNS record details
 */
async function createWorkspaceDnsRecord(employee, nodeIp, nodePort) {
  const dnsName = generateDnsName(employee);
  const fqdn = `${dnsName}.`;

  logger.info(`Creating DNS record: ${dnsName} -> ${nodeIp}`);

  const params = {
    HostedZoneId: HOSTED_ZONE_ID,
    ChangeBatch: {
      Comment: `Workspace DNS for ${employee.firstName} ${employee.lastName}`,
      Changes: [
        {
          Action: 'UPSERT',
          ResourceRecordSet: {
            Name: fqdn,
            Type: 'A',
            TTL: 60, // Short TTL for quick updates
            ResourceRecords: [
              { Value: nodeIp }
            ]
          }
        }
      ]
    }
  };

  try {
    const command = new ChangeResourceRecordSetsCommand(params);
    const response = await route53.send(command);
    
    logger.info(`DNS record created: ${dnsName} -> ${nodeIp} (ChangeId: ${response.ChangeInfo?.Id})`);
    
    return {
      success: true,
      dnsName,
      fqdn,
      nodeIp,
      nodePort,
      url: `https://${dnsName}:${nodePort}`,
      changeId: response.ChangeInfo?.Id
    };
  } catch (error) {
    logger.error(`Failed to create DNS record for ${dnsName}:`, error);
    throw error;
  }
}

/**
 * Delete DNS record for workspace
 * @param {object} employee - Employee data
 * @param {string} nodeIp - IP address to remove
 */
async function deleteWorkspaceDnsRecord(employee, nodeIp) {
  const dnsName = generateDnsName(employee);
  const fqdn = `${dnsName}.`;

  logger.info(`Deleting DNS record: ${dnsName}`);

  // First check if record exists
  try {
    const listParams = {
      HostedZoneId: HOSTED_ZONE_ID,
      StartRecordName: fqdn,
      StartRecordType: 'A',
      MaxItems: 1
    };

    const listCommand = new ListResourceRecordSetsCommand(listParams);
    const listResponse = await route53.send(listCommand);
    
    const existingRecord = listResponse.ResourceRecordSets?.find(
      r => r.Name === fqdn && r.Type === 'A'
    );

    if (!existingRecord) {
      logger.info(`DNS record ${dnsName} does not exist, skipping deletion`);
      return { success: true, message: 'Record did not exist' };
    }

    // Delete the record
    const deleteParams = {
      HostedZoneId: HOSTED_ZONE_ID,
      ChangeBatch: {
        Comment: `Remove workspace DNS for ${employee.firstName} ${employee.lastName}`,
        Changes: [
          {
            Action: 'DELETE',
            ResourceRecordSet: existingRecord
          }
        ]
      }
    };

    const deleteCommand = new ChangeResourceRecordSetsCommand(deleteParams);
    await route53.send(deleteCommand);
    
    logger.info(`DNS record deleted: ${dnsName}`);
    return { success: true, dnsName };

  } catch (error) {
    if (error.name === 'InvalidChangeBatch') {
      logger.warn(`DNS record ${dnsName} already deleted or not found`);
      return { success: true, message: 'Record already deleted' };
    }
    logger.error(`Failed to delete DNS record for ${dnsName}:`, error);
    throw error;
  }
}

/**
 * Get DNS record for employee workspace
 */
async function getWorkspaceDnsRecord(employee) {
  const dnsName = generateDnsName(employee);
  const fqdn = `${dnsName}.`;

  try {
    const listParams = {
      HostedZoneId: HOSTED_ZONE_ID,
      StartRecordName: fqdn,
      StartRecordType: 'A',
      MaxItems: 1
    };

    const listCommand = new ListResourceRecordSetsCommand(listParams);
    const listResponse = await route53.send(listCommand);
    
    const record = listResponse.ResourceRecordSets?.find(
      r => r.Name === fqdn && r.Type === 'A'
    );

    if (record) {
      return {
        exists: true,
        dnsName,
        ip: record.ResourceRecords?.[0]?.Value,
        ttl: record.TTL
      };
    }

    return { exists: false, dnsName };
  } catch (error) {
    logger.error(`Failed to get DNS record for ${dnsName}:`, error);
    return { exists: false, dnsName, error: error.message };
  }
}

module.exports = {
  createWorkspaceDnsRecord,
  deleteWorkspaceDnsRecord,
  getWorkspaceDnsRecord,
  generateDnsName,
  sanitizeDnsLabel,
  DOMAIN
};
