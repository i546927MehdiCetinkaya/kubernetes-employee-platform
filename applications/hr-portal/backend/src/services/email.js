const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const ssmService = require('./ssm');
const logger = require('../utils/logger');

const AWS_REGION = process.env.AWS_REGION || 'eu-west-1';
const sesClient = new SESClient({ region: AWS_REGION });

/**
 * Send welcome email to new employee with workspace credentials
 */
async function sendWelcomeEmail(employee, workspace, temporaryPassword) {
  try {
    // Get email configuration from SSM
    const emailConfig = await ssmService.getEmailConfig();

    const workspaceUrl = workspace.url || `https://${workspace.name}.${emailConfig.workspace_domain}`;

    // Email template defined here (SSM doesn't support {{}} template variables)
    const emailTemplate = {
      subject: 'Welcome to InnovaTech - Your Workspace is Ready!',
      html_body: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #0066cc; color: white; padding: 20px; text-align: center; }
            .content { background: #f9f9f9; padding: 30px; }
            .credentials { background: white; padding: 20px; border-left: 4px solid #0066cc; margin: 20px 0; }
            .button { background: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to InnovaTech!</h1>
            </div>
            <div class="content">
              <p>Dear {{firstName}} {{lastName}},</p>
              <p>Your development workspace has been provisioned and is ready to use!</p>
              
              <div class="credentials">
                <h3>🔐 Your Workspace Credentials</h3>
                <p><strong>Workspace URL:</strong> <a href="{{workspaceUrl}}">{{workspaceUrl}}</a></p>
                <p><strong>Username:</strong> coder</p>
                <p><strong>Temporary Password:</strong> <code>{{tempPassword}}</code></p>
              </div>

              <div class="warning">
                <strong>⚠️ Important Security Notice</strong>
                <p>This is a <strong>temporary password</strong> that must be changed on your first login.</p>
                <p>This password will expire in <strong>24 hours</strong>.</p>
              </div>

              <a href="{{workspaceUrl}}" class="button">Access Your Workspace</a>

              <h3>Getting Started</h3>
              <ol>
                <li>Click the button above or open the workspace URL in your browser</li>
                <li>Log in with the username "coder" and your temporary password</li>
                <li>You will be prompted to set a new password</li>
                <li>Start coding in your personal VS Code environment!</li>
              </ol>

              <p>Your workspace includes:</p>
              <ul>
                <li>Full VS Code editor in your browser</li>
                <li>10GB persistent storage</li>
                <li>Pre-configured development tools</li>
                <li>Secure, isolated environment</li>
              </ul>

              <p>If you have any questions, please contact HR or IT support.</p>
              
              <p>Best regards,<br>InnovaTech HR Team</p>
            </div>
            <div class="footer">
              <p>© 2025 InnovaTech. All rights reserved.</p>
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text_body: 'Dear {{firstName}} {{lastName}},\n\nYour workspace is ready!\n\nWorkspace URL: {{workspaceUrl}}\nUsername: coder\nTemporary Password: {{tempPassword}}\n\nPlease change your password on first login.\n\nBest regards,\nInnovaTech HR Team'
    };

    // Replace template variables
    const htmlBody = replaceTemplateVariables(emailTemplate.html_body, {
      firstName: employee.firstName,
      lastName: employee.lastName,
      workspaceUrl: workspaceUrl,
      tempPassword: temporaryPassword
    });

    const textBody = replaceTemplateVariables(emailTemplate.text_body, {
      firstName: employee.firstName,
      lastName: employee.lastName,
      workspaceUrl: workspaceUrl,
      tempPassword: temporaryPassword
    });

    const params = {
      Source: `${emailConfig.sender_name} <${emailConfig.sender_email}>`,
      Destination: {
        ToAddresses: [employee.email]
      },
      Message: {
        Subject: {
          Data: emailTemplate.subject,
          Charset: 'UTF-8'
        },
        Body: {
          Html: {
            Data: htmlBody,
            Charset: 'UTF-8'
          },
          Text: {
            Data: textBody,
            Charset: 'UTF-8'
          }
        }
      },
      ReplyToAddresses: [emailConfig.sender_email]
    };

    const command = new SendEmailCommand(params);
    const response = await sesClient.send(command);

    logger.info(`Welcome email sent to ${employee.email}, MessageId: ${response.MessageId}`);
    
    return {
      success: true,
      messageId: response.MessageId,
      recipient: employee.email
    };
  } catch (error) {
    logger.error(`Failed to send welcome email to ${employee.email}:`, error);
    throw new Error(`Email sending failed: ${error.message}`);
  }
}

/**
 * Send password reset email
 */
async function sendPasswordResetEmail(employee, resetToken) {
  try {
    const emailConfig = await ssmService.getEmailConfig();
    const resetUrl = `https://hr-portal.innovatech.com/reset-password?token=${resetToken}`;

    const htmlBody = `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Password Reset Request</h2>
        <p>Dear ${employee.firstName} ${employee.lastName},</p>
        <p>We received a request to reset your workspace password.</p>
        <p><a href="${resetUrl}" style="background: #0066cc; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a></p>
        <p>If you didn't request this, please ignore this email.</p>
        <p>This link expires in 1 hour.</p>
        <p>Best regards,<br>InnovaTech IT Team</p>
      </body>
      </html>
    `;

    const textBody = `Dear ${employee.firstName} ${employee.lastName},\n\nPassword reset link: ${resetUrl}\n\nThis link expires in 1 hour.\n\nBest regards,\nInnovaTech IT Team`;

    const params = {
      Source: `${emailConfig.sender_name} <${emailConfig.sender_email}>`,
      Destination: {
        ToAddresses: [employee.email]
      },
      Message: {
        Subject: {
          Data: 'Password Reset Request',
          Charset: 'UTF-8'
        },
        Body: {
          Html: {
            Data: htmlBody,
            Charset: 'UTF-8'
          },
          Text: {
            Data: textBody,
            Charset: 'UTF-8'
          }
        }
      }
    };

    const command = new SendEmailCommand(params);
    const response = await sesClient.send(command);

    logger.info(`Password reset email sent to ${employee.email}, MessageId: ${response.MessageId}`);
    return { success: true, messageId: response.MessageId };
  } catch (error) {
    logger.error(`Failed to send password reset email to ${employee.email}:`, error);
    throw new Error(`Email sending failed: ${error.message}`);
  }
}

/**
 * Send workspace termination notification
 */
async function sendWorkspaceTerminationEmail(employee, terminationDate) {
  try {
    const emailConfig = await ssmService.getEmailConfig();

    const htmlBody = `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Workspace Termination Notice</h2>
        <p>Dear ${employee.firstName} ${employee.lastName},</p>
        <p>Your workspace will be terminated on <strong>${terminationDate}</strong>.</p>
        <p><strong>Important:</strong> Please backup any important data before this date.</p>
        <p>If you have questions, please contact HR.</p>
        <p>Best regards,<br>InnovaTech HR Team</p>
      </body>
      </html>
    `;

    const textBody = `Dear ${employee.firstName} ${employee.lastName},\n\nYour workspace will be terminated on ${terminationDate}.\n\nPlease backup any important data before this date.\n\nBest regards,\nInnovaTech HR Team`;

    const params = {
      Source: `${emailConfig.sender_name} <${emailConfig.sender_email}>`,
      Destination: {
        ToAddresses: [employee.email]
      },
      Message: {
        Subject: {
          Data: 'Workspace Termination Notice',
          Charset: 'UTF-8'
        },
        Body: {
          Html: {
            Data: htmlBody,
            Charset: 'UTF-8'
          },
          Text: {
            Data: textBody,
            Charset: 'UTF-8'
          }
        }
      }
    };

    const command = new SendEmailCommand(params);
    const response = await sesClient.send(command);

    logger.info(`Termination email sent to ${employee.email}, MessageId: ${response.MessageId}`);
    return { success: true, messageId: response.MessageId };
  } catch (error) {
    logger.error(`Failed to send termination email to ${employee.email}:`, error);
    throw new Error(`Email sending failed: ${error.message}`);
  }
}

/**
 * Replace template variables with actual values
 */
function replaceTemplateVariables(template, variables) {
  let result = template;
  for (const [key, value] of Object.entries(variables)) {
    const regex = new RegExp(`{{${key}}}`, 'g');
    result = result.replace(regex, value);
  }
  return result;
}

module.exports = {
  sendWelcomeEmail,
  sendPasswordResetEmail,
  sendWorkspaceTerminationEmail
};
