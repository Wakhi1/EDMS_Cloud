import 'package:flutter/material.dart';

import '../../../core/models/folder_row.dart';
import '../../../core/models/integration_row.dart';

/// What the editor returns: the fields PUT /api/integrations/:id accepts.
typedef IntegrationEdit = ({String name, String description, String status, String endpoint, Map<String, dynamic>? configJson});

const _kIntegrationStatuses = <String>['connected', 'disconnected', 'error'];

/// Automated intake connector ids — these get structured config_json fields
/// (host/path/interval/enabled) instead of just name/description/endpoint,
/// since editing their connection settings and turning polling on/off is
/// the whole point of opening this dialog for them.
const _kIntakeConnectorIds = <String>['watched_folder', 'ftp', 'email_intake'];

/// Edits an integration's status/endpoint (and, for the three automated
/// intake connectors, their config_json connection settings). Returns the
/// edited values on save, or null if cancelled — the actual PUT call
/// happens in the caller (integrations_screen.dart), same "pure editor,
/// caller mutates" shape as EditRetentionClassDialog.
class EditIntegrationDialog extends StatefulWidget {
  const EditIntegrationDialog({super.key, required this.integration, this.onSubmit, this.folders = const []});

  final IntegrationRow integration;

  /// When set, the form renders inline (no dialog chrome) and Save calls this
  /// instead of popping — used by the Integrations screen's settings pane.
  final Future<void> Function(IntegrationEdit result)? onSubmit;

  /// Repository folders, for the intake connectors' destination picker.
  final List<FolderRow> folders;

  @override
  State<EditIntegrationDialog> createState() => _EditIntegrationDialogState();
}

class _EditIntegrationDialogState extends State<EditIntegrationDialog> {
  late final _nameController = TextEditingController(text: widget.integration.name);
  late final _descriptionController = TextEditingController(text: widget.integration.description ?? '');
  late final _endpointController = TextEditingController(text: widget.integration.endpoint ?? '');
  late String _status = widget.integration.status;

  // Connector config fields — only used/shown when the integration id is
  // one of _kIntakeConnectorIds.
  late final Map<String, dynamic> _config = Map<String, dynamic>.from(widget.integration.configJson ?? {});
  late final _hostController = TextEditingController(text: '${_config['host'] ?? ''}');
  late final _portController = TextEditingController(text: '${_config['port'] ?? ''}');
  late final _userController = TextEditingController(text: '${_config['user'] ?? ''}');
  late final _pathController = TextEditingController(text: '${_config['path'] ?? ''}');
  late final _mailboxController = TextEditingController(text: '${_config['mailbox'] ?? ''}');
  final _passwordController = TextEditingController();
  late final _intervalController = TextEditingController(text: '${_config['pollIntervalSeconds'] ?? _config['pollIntervalMinutes'] ?? ''}');
  late bool _enabled = _config['enabled'] == true;
  // Intake destination (capture/scheduler.js reads config.defaultFolderId) and FTP TLS options.
  late int? _defaultFolderId = (_config['defaultFolderId'] as num?)?.toInt();
  late bool _ftpSecure = _config['secure'] == true;
  late bool _ftpAllowSelfSigned = _config['allowSelfSigned'] == true;
  bool _saving = false;

  // Active Directory config fields — only used/shown when this is the 'ad'
  // integration. The bind password is deliberately not editable here, same
  // env-var-not-DB convention as the FTP/email password note above.
  late final _adUrlController = TextEditingController(text: '${_config['url'] ?? ''}');
  late final _adBindDnController = TextEditingController(text: '${_config['bindDN'] ?? ''}');
  late final _adSearchBaseController = TextEditingController(text: '${_config['searchBase'] ?? ''}');
  late final _adSearchFilterController = TextEditingController(text: '${_config['searchFilter'] ?? ''}');
  late bool _adTlsRejectUnauthorized = _config['tlsRejectUnauthorized'] != false;

  // SMS (Vonage) config fields — only used/shown for the 'sms' integration.
  // The API key/secret are deliberately not editable here, same
  // env-var-not-DB convention as the AD bind password above.
  late final _smsFromController = TextEditingController(text: '${_config['from'] ?? ''}');

  // SMTP config fields — only used/shown for the 'smtp' integration. Reuses
  // _hostController/_portController/_userController/_passwordController
  // (already declared above, generically named, otherwise unused by this
  // branch) rather than duplicating them.
  late final _smtpFromController = TextEditingController(text: '${_config['from'] ?? ''}');
  late bool _smtpSecure = _config['secure'] == true;

  // AWS S3 config fields — only used/shown for the 'aws_s3' integration.
  // secretAccessKey is blank-by-default, same "leave blank to keep the
  // current value" convention as every other secret field above.
  late final _awsRegionController = TextEditingController(text: '${_config['region'] ?? ''}');
  late final _awsAccessKeyIdController = TextEditingController(text: '${_config['accessKeyId'] ?? ''}');
  final _awsSecretAccessKeyController = TextEditingController();
  late final _awsBucketController = TextEditingController(text: '${_config['bucket'] ?? ''}');

  // Azure Blob Storage config fields — only used/shown for 'azure_blob'.
  // connectionString is the one secret field here (it embeds the account
  // key) — blank-by-default, same convention.
  final _azureConnectionStringController = TextEditingController();
  late final _azureContainerController = TextEditingController(text: '${_config['container'] ?? ''}');

  // GCP Storage config fields — only used/shown for 'gcp_storage'.
  // serviceAccountJson lets an admin paste the whole downloaded key file's
  // content here instead of needing server filesystem access for
  // keyFilePath — blank-by-default, same convention.
  late final _gcpProjectIdController = TextEditingController(text: '${_config['projectId'] ?? ''}');
  late final _gcpBucketController = TextEditingController(text: '${_config['bucket'] ?? ''}');
  late final _gcpKeyFilePathController = TextEditingController(text: '${_config['keyFilePath'] ?? ''}');
  final _gcpServiceAccountJsonController = TextEditingController();

  // Local disk config fields — only used/shown for 'local'. Not a secret
  // (a server-local path, same treatment as the watched-folder root).
  late final _localRootPathController = TextEditingController(text: '${_config['rootPath'] ?? ''}');

  // Outbound webhook config fields — only used/shown for 'webhook'. Reuses
  // _intervalController (already declared above, generic, otherwise unused
  // by this branch) for the push interval. authToken is blank-by-default,
  // same "leave blank to keep the current value" convention.
  late final _webhookUrlController = TextEditingController(text: '${_config['url'] ?? ''}');
  final _webhookAuthTokenController = TextEditingController();

  bool get _isIntakeConnector => _kIntakeConnectorIds.contains(widget.integration.id);
  bool get _isAd => widget.integration.id == 'ad';
  bool get _isSms => widget.integration.id == 'sms';
  bool get _isSmtp => widget.integration.id == 'smtp';
  bool get _isAwsS3 => widget.integration.id == 'aws_s3';
  bool get _isAzureBlob => widget.integration.id == 'azure_blob';
  bool get _isGcpStorage => widget.integration.id == 'gcp_storage';
  bool get _isLocal => widget.integration.id == 'local';
  bool get _isWebhook => widget.integration.id == 'webhook';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _endpointController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _pathController.dispose();
    _mailboxController.dispose();
    _passwordController.dispose();
    _intervalController.dispose();
    _adUrlController.dispose();
    _adBindDnController.dispose();
    _adSearchBaseController.dispose();
    _adSearchFilterController.dispose();
    _smsFromController.dispose();
    _smtpFromController.dispose();
    _awsRegionController.dispose();
    _awsAccessKeyIdController.dispose();
    _awsSecretAccessKeyController.dispose();
    _awsBucketController.dispose();
    _azureConnectionStringController.dispose();
    _azureContainerController.dispose();
    _gcpProjectIdController.dispose();
    _gcpBucketController.dispose();
    _gcpKeyFilePathController.dispose();
    _gcpServiceAccountJsonController.dispose();
    _localRootPathController.dispose();
    _webhookUrlController.dispose();
    _webhookAuthTokenController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildAdConfigJson() {
    return {
      'url': _adUrlController.text.trim(),
      'bindDN': _adBindDnController.text.trim(),
      'searchBase': _adSearchBaseController.text.trim(),
      'searchFilter': _adSearchFilterController.text.trim(),
      'tlsRejectUnauthorized': _adTlsRejectUnauthorized,
      'enabled': _enabled,
    };
  }

  Map<String, dynamic> _buildSmsConfigJson() {
    return {'provider': 'vonage', 'from': _smsFromController.text.trim().isEmpty ? 'PSPFEDMS' : _smsFromController.text.trim(), 'enabled': _enabled};
  }

  Map<String, dynamic> _buildSmtpConfigJson() {
    return {
      'host': _hostController.text.trim(),
      'port': int.tryParse(_portController.text) ?? 587,
      'secure': _smtpSecure,
      'user': _userController.text.trim(),
      // Blank means "leave the currently-saved password alone" — same
      // backend merge-on-blank behavior as the intake connectors above.
      if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      'from': _smtpFromController.text.trim(),
      'enabled': _enabled,
    };
  }

  Map<String, dynamic> _buildAwsConfigJson() {
    return {
      'region': _awsRegionController.text.trim(),
      'accessKeyId': _awsAccessKeyIdController.text.trim(),
      // Blank means "leave the currently-saved secret key alone" — the
      // backend merges in the existing value when this key is omitted.
      if (_awsSecretAccessKeyController.text.isNotEmpty) 'secretAccessKey': _awsSecretAccessKeyController.text,
      'bucket': _awsBucketController.text.trim(),
    };
  }

  Map<String, dynamic> _buildAzureConfigJson() {
    return {
      if (_azureConnectionStringController.text.isNotEmpty) 'connectionString': _azureConnectionStringController.text,
      'container': _azureContainerController.text.trim(),
    };
  }

  Map<String, dynamic> _buildGcpConfigJson() {
    return {
      'projectId': _gcpProjectIdController.text.trim(),
      'bucket': _gcpBucketController.text.trim(),
      'keyFilePath': _gcpKeyFilePathController.text.trim(),
      if (_gcpServiceAccountJsonController.text.isNotEmpty) 'serviceAccountJson': _gcpServiceAccountJsonController.text,
    };
  }

  Map<String, dynamic> _buildLocalConfigJson() {
    return {'rootPath': _localRootPathController.text.trim()};
  }

  Map<String, dynamic> _buildWebhookConfigJson() {
    return {
      'url': _webhookUrlController.text.trim(),
      // Blank means "leave the currently-saved auth token alone" — same
      // backend merge-on-blank behavior as every other secret field above.
      if (_webhookAuthTokenController.text.isNotEmpty) 'authToken': _webhookAuthTokenController.text,
      'pollIntervalMinutes': int.tryParse(_intervalController.text) ?? 15,
      'enabled': _enabled,
    };
  }

  Map<String, dynamic>? _buildConfigJsonForSave() {
    if (_isIntakeConnector) return _buildConfigJson();
    if (_isAd) return _buildAdConfigJson();
    if (_isSms) return _buildSmsConfigJson();
    if (_isSmtp) return _buildSmtpConfigJson();
    if (_isAwsS3) return _buildAwsConfigJson();
    if (_isAzureBlob) return _buildAzureConfigJson();
    if (_isGcpStorage) return _buildGcpConfigJson();
    if (_isLocal) return _buildLocalConfigJson();
    if (_isWebhook) return _buildWebhookConfigJson();
    return null;
  }

  Map<String, dynamic> _buildConfigJson() {
    final id = widget.integration.id;
    final interval = int.tryParse(_intervalController.text) ?? 0;
    return {
      'host': _hostController.text.trim(),
      'port': int.tryParse(_portController.text) ?? (id == 'email_intake' ? 993 : 21),
      'user': _userController.text.trim(),
      // Blank means "leave the currently-saved password alone" — the
      // backend (integrations.routes.js PUT /:id) merges in the existing
      // value when this key is empty/absent, rather than wiping it.
      if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      if (id == 'watched_folder') 'path': _pathController.text.trim(),
      if (id == 'ftp') 'path': _pathController.text.trim().isEmpty ? '/' : _pathController.text.trim(),
      if (id == 'email_intake') 'mailbox': _mailboxController.text.trim().isEmpty ? 'INBOX' : _mailboxController.text.trim(),
      if (id == 'watched_folder') 'pollIntervalSeconds': interval,
      if (id == 'ftp' || id == 'email_intake') 'pollIntervalMinutes': interval,
      if (id == 'ftp') 'secure': _ftpSecure,
      if (id == 'ftp') 'allowSelfSigned': _ftpAllowSelfSigned,
      'defaultFolderId': ?_defaultFolderId,
      'enabled': _enabled,
    };
  }

  IntegrationEdit _result() => (
    name: _nameController.text.trim(),
    description: _descriptionController.text.trim(),
    status: _status,
    endpoint: _isAd ? _adUrlController.text.trim() : _endpointController.text.trim(),
    configJson: _buildConfigJsonForSave(),
  );

  Future<void> _saveInline() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit!(_result());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _form(context);
    if (widget.onSubmit != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          form,
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _saveInline,
            child: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text('Edit ${widget.integration.name}'),
      content: SizedBox(width: 380, child: SingleChildScrollView(child: form)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(_result()), child: const Text('Save')),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 12),
        if (!_isIntakeConnector && !_isAd && !_isSms && !_isSmtp && !_isAwsS3 && !_isAzureBlob && !_isGcpStorage && !_isLocal && !_isWebhook) ...[
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(labelText: 'Endpoint'),
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          initialValue: _status,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Status'),
          items: [for (final s in _kIntegrationStatuses) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        if (_isIntakeConnector) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          if (widget.integration.id != 'watched_folder') ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(labelText: 'Host'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', hintText: 'Leave blank to keep the current password'),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.integration.id == 'watched_folder')
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(labelText: 'Subfolder (blank = root intake directory)'),
            ),
          if (widget.integration.id == 'ftp')
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(labelText: 'Remote path'),
            ),
          if (widget.integration.id == 'email_intake')
            TextField(
              controller: _mailboxController,
              decoration: const InputDecoration(labelText: 'Mailbox'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: widget.integration.id == 'watched_folder' ? 'Poll interval (seconds)' : 'Poll interval (minutes)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: widget.folders.any((f) => f.id == _defaultFolderId) ? _defaultFolderId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Destination folder in the Repository', helperText: 'Captured files are filed here'),
            items: [
              for (final f in [...widget.folders]..sort((a, b) => a.path.compareTo(b.path)))
                DropdownMenuItem<int?>(
                  value: f.id,
                  child: Text(f.path, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _defaultFolderId = v),
          ),
          if (widget.integration.id == 'ftp') ...[
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _ftpSecure,
              onChanged: (v) => setState(() => _ftpSecure = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Use FTPS (explicit TLS) — recommended'),
            ),
            if (_ftpSecure)
              CheckboxListTile(
                value: _ftpAllowSelfSigned,
                onChanged: (v) => setState(() => _ftpAllowSelfSigned = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Accept the server\'s own certificate (shared hosting)'),
              ),
          ],
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Enabled — poll automatically while the server is running'),
          ),
        ],
        if (_isAd) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _adUrlController,
            decoration: const InputDecoration(labelText: 'URL (e.g. ldaps://dc01.example.local:636)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adBindDnController,
            decoration: const InputDecoration(labelText: 'Service account bind DN'),
          ),
          const SizedBox(height: 12),
          const Text('Bind password is set via the backend .env file (AD_BIND_PASSWORD), not here.', style: TextStyle(fontSize: 11.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _adSearchBaseController,
            decoration: const InputDecoration(labelText: 'Search base (e.g. dc=example,dc=local)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adSearchFilterController,
            decoration: const InputDecoration(labelText: 'Search filter ({{email}} is substituted)'),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _adTlsRejectUnauthorized,
            onChanged: (v) => setState(() => _adTlsRejectUnauthorized = v ?? true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Reject unauthorized TLS certificates'),
          ),
          CheckboxListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Enabled'),
          ),
        ],
        if (_isSms) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _smsFromController,
            decoration: const InputDecoration(labelText: 'Sender ID (shown to recipients as "from")'),
          ),
          const SizedBox(height: 12),
          const Text(
            'API key/secret are set via the backend .env file (VONAGE_API_KEY / VONAGE_API_SECRET), not here. '
            'Only users with a valid phone number in international format (e.g. +268...) are offered SMS as an MFA method.',
            style: TextStyle(fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Enabled'),
          ),
        ],
        if (_isSmtp) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(labelText: 'Host'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', hintText: 'Leave blank to keep the current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _smtpFromController,
            decoration: const InputDecoration(labelText: 'From', hintText: 'PSPF EDMS <no-reply@pspf.co.sz>'),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _smtpSecure,
            onChanged: (v) => setState(() => _smtpSecure = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Use TLS/SSL (secure)'),
          ),
          CheckboxListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Enabled'),
          ),
        ],
        if (_isAwsS3) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _awsRegionController,
            decoration: const InputDecoration(labelText: 'Region (e.g. eu-north-1)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _awsAccessKeyIdController,
            decoration: const InputDecoration(labelText: 'Access key ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _awsSecretAccessKeyController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Secret access key', hintText: 'Leave blank to keep the current value'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _awsBucketController,
            decoration: const InputDecoration(labelText: 'Bucket'),
          ),
        ],
        if (_isAzureBlob) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _azureConnectionStringController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Connection string', hintText: 'Leave blank to keep the current value'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _azureContainerController,
            decoration: const InputDecoration(labelText: 'Container'),
          ),
        ],
        if (_isGcpStorage) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _gcpProjectIdController,
            decoration: const InputDecoration(labelText: 'Project ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gcpBucketController,
            decoration: const InputDecoration(labelText: 'Bucket'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gcpServiceAccountJsonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Service account JSON key',
              hintText: 'Paste the downloaded key file\'s contents — leave blank to keep the current value',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gcpKeyFilePathController,
            decoration: const InputDecoration(labelText: 'Key file path (used only if no JSON key is set above)'),
          ),
        ],
        if (_isLocal) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _localRootPathController,
            decoration: const InputDecoration(labelText: 'Root path on the server'),
          ),
        ],
        if (_isWebhook) ...[
          const Divider(height: 28),
          Text('Connection', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _webhookUrlController,
            decoration: const InputDecoration(labelText: 'Webhook URL', hintText: 'https://example.com/hooks/pspf-edms'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _webhookAuthTokenController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Auth token (sent as Bearer)', hintText: 'Leave blank to keep the current value'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Push interval (minutes)'),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Enabled — push automatically while the server is running'),
          ),
        ],
      ],
    );
  }
}
