/// Step-by-step setup notes shown next to each integration's settings.
/// Written for the common hosting setups (cPanel/Namecheap, AWS, Azure,
/// Google Cloud) — each step says where to click and what to copy here.
class IntegrationGuide {
  const IntegrationGuide({required this.summary, required this.steps, this.tips = const []});

  /// One line: what this integration does in the EDMS.
  final String summary;
  final List<String> steps;
  final List<String> tips;
}

const kIntegrationGuides = <String, IntegrationGuide>{
  'ftp': IntegrationGuide(
    summary:
        'Polls a folder on an FTP server and captures every new file into the Repository. '
        'Processed files are moved to a "processed" subfolder on the server so they are never captured twice.',
    steps: [
      'In cPanel, open Files → FTP Accounts.',
      'Log In: e.g. "edms-intake"; pick your domain; set a strong password (use the generator).',
      'Directory: use a folder outside public_html, e.g. "edms-intake" (cPanel creates /home/<you>/edms-intake) so scans are never reachable from the web.',
      'Set Quota to a sensible limit (or Unlimited) and click Create FTP Account.',
      'In the account list click "Configure FTP Client" — note the FTP Username (it includes @yourdomain), Server (ftp.yourdomain) and Port (21).',
      'Here: Host = ftp.yourdomain, Port = 21, Username = the full username including @yourdomain, Password = the one you set.',
      'Remote path = "/" — the FTP account is locked to its own directory, so "/" is that folder.',
      'Tick "Use FTPS (explicit TLS)" — cPanel supports it and it keeps the password and files encrypted in transit.',
      'Choose the Repository folder new files should land in, set a poll interval (e.g. 5 minutes), tick Enabled, then Save and Test connection.',
    ],
    tips: [
      'If the test fails with a certificate error, tick "Accept the server\'s own certificate" — shared hosts often present the server\'s certificate instead of one for your domain.',
      'A scanner or another system can now drop files into this FTP account; they appear in the Repository on the next poll.',
    ],
  ),
  'email_intake': IntegrationGuide(
    summary: 'Reads a mailbox and captures every attachment of unread messages — ideal for a scanner\'s "scan to email".',
    steps: [
      'In cPanel, open Email → Email Accounts → Create, e.g. "scans@yourdomain".',
      'Click "Connect Devices" next to the account — note the Incoming Server (mail.yourdomain) and IMAP port (993, SSL).',
      'Here: Host = mail.yourdomain, Port = 993, Username = the full email address, Password = the mailbox password.',
      'Mailbox = INBOX (or a folder you route scans into).',
      'Choose the destination Repository folder, set a poll interval, tick Enabled, Save and Test connection.',
    ],
    tips: ['Messages are marked as read once their attachments are captured, so they are not captured twice.'],
  ),
  'watched_folder': IntegrationGuide(
    summary: 'Captures files dropped into a folder on this server. For a folder on someone\'s own PC, use the Local agent instead.',
    steps: [
      'Files are read from the server\'s intake directory (WATCHED_INTAKE_ROOT in the backend .env, default ./watched-intake).',
      'Subfolder: leave blank for the whole intake directory, or name a subfolder inside it.',
      'Choose the destination Repository folder, set a poll interval in seconds, tick Enabled and Save.',
    ],
  ),
  'aws_s3': IntegrationGuide(
    summary: 'Stores documents in an Amazon S3 bucket, and lets you browse and register content that is already there.',
    steps: [
      'In the AWS console create (or pick) a bucket; note its name and region (e.g. eu-north-1).',
      'IAM → Users → Create user (no console access). Attach a policy allowing s3:ListBucket on the bucket and s3:GetObject, s3:PutObject, s3:DeleteObject on its objects.',
      'Open the user → Security credentials → Create access key (type: "Application running outside AWS"). Copy the Access key ID and Secret.',
      'Fill in Region, Access key ID, Secret access key and Bucket here, Save, then Test connection.',
    ],
    tips: ['Keep Block Public Access on — the EDMS reads and writes with the key; nothing needs to be public.'],
  ),
  'azure_blob': IntegrationGuide(
    summary: 'Stores documents in an Azure Blob Storage container.',
    steps: [
      'In the Azure portal open your Storage account → Data storage → Containers → + Container (private access).',
      'Storage account → Security + networking → Access keys → Show → copy "Connection string" (key1).',
      'Paste the connection string and the container name here, Save, then Test connection.',
    ],
  ),
  'gcp_storage': IntegrationGuide(
    summary: 'Stores documents in a Google Cloud Storage bucket.',
    steps: [
      'In Google Cloud Console create a bucket (uniform access, not public); note the project ID and bucket name.',
      'IAM & Admin → Service accounts → Create; grant "Storage Object Admin" on the bucket.',
      'Open the service account → Keys → Add key → JSON. Paste the whole downloaded file into "Service account JSON key".',
      'Fill in Project ID and Bucket, Save, then Test connection.',
    ],
  ),
  'local': IntegrationGuide(
    summary: 'Stores documents on this server\'s own disk.',
    steps: [
      'Root path: an absolute folder the backend can write to. On cPanel use a folder outside public_html, e.g. /home/<cpanel-user>/edms-storage.',
      'Create the folder first (cPanel → File Manager → + Folder), Save here, then Test connection.',
    ],
    tips: ['Include this folder in your cPanel backups — documents stored here are not copied anywhere else.'],
  ),
  'smtp': IntegrationGuide(
    summary: 'Sends notification, approval and password-reset emails.',
    steps: [
      'In cPanel, open Email → Email Accounts and create e.g. "no-reply@yourdomain".',
      'Click "Connect Devices" — note the Outgoing Server (mail.yourdomain) and SMTP port (465 with SSL).',
      'Here: Host = mail.yourdomain, Port = 465, tick "Use TLS/SSL", Username = the full email address, Password = its password.',
      'From: e.g. "Docsecure EDMS <no-reply@yourdomain>". Tick Enabled, Save, then Test connection.',
    ],
    tips: ['Port 587 also works — then leave "Use TLS/SSL" unticked (the connection upgrades with STARTTLS).'],
  ),
  'ad': IntegrationGuide(
    summary: 'Lets staff sign in with their Active Directory accounts.',
    steps: [
      'URL: your domain controller, e.g. ldaps://dc01.example.local:636.',
      'Bind DN: a read-only service account, e.g. CN=svc-edms,OU=Service Accounts,DC=example,DC=local. Its password goes in the backend .env (AD_BIND_PASSWORD).',
      'Search base: where user accounts live, e.g. DC=example,DC=local. Filter: (mail={{email}}).',
      'Tick Enabled, Save, then Test connection.',
    ],
  ),
  'sms': IntegrationGuide(
    summary: 'Sends one-time passcodes by SMS for multi-factor sign-in (Vonage).',
    steps: [
      'Create a Vonage API account; copy the API key and secret into the backend .env (VONAGE_API_KEY / VONAGE_API_SECRET).',
      'Sender ID: up to 11 letters shown as the sender, e.g. DOCSECURE. Tick Enabled and Save.',
    ],
  ),
  'webhook': IntegrationGuide(
    summary: 'Pushes record events to another system as JSON on a schedule.',
    steps: [
      'Webhook URL: an HTTPS endpoint on the receiving system that accepts POST requests.',
      'Auth token: shared secret sent as "Authorization: Bearer <token>" so the receiver can verify the call.',
      'Set the push interval, tick Enabled, Save and Test connection.',
    ],
  ),
};
