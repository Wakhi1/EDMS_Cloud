import 'package:flutter/material.dart';

import '../../../core/models/integration_row.dart';

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
  const EditIntegrationDialog({super.key, required this.integration});

  final IntegrationRow integration;

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
  late final _intervalController = TextEditingController(
    text: '${_config['pollIntervalSeconds'] ?? _config['pollIntervalMinutes'] ?? ''}',
  );
  late bool _enabled = _config['enabled'] == true;

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

  bool get _isIntakeConnector => _kIntakeConnectorIds.contains(widget.integration.id);
  bool get _isAd => widget.integration.id == 'ad';
  bool get _isSms => widget.integration.id == 'sms';

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
    _intervalController.dispose();
    _adUrlController.dispose();
    _adBindDnController.dispose();
    _adSearchBaseController.dispose();
    _adSearchFilterController.dispose();
    _smsFromController.dispose();
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
    return {
      'provider': 'vonage',
      'from': _smsFromController.text.trim().isEmpty ? 'PSPFEDMS' : _smsFromController.text.trim(),
      'enabled': _enabled,
    };
  }

  Map<String, dynamic> _buildConfigJson() {
    final id = widget.integration.id;
    final interval = int.tryParse(_intervalController.text) ?? 0;
    return {
      'host': _hostController.text.trim(),
      'port': int.tryParse(_portController.text) ?? (id == 'email_intake' ? 993 : 21),
      'user': _userController.text.trim(),
      if (id == 'watched_folder') 'path': _pathController.text.trim(),
      if (id == 'ftp') 'path': _pathController.text.trim().isEmpty ? '/' : _pathController.text.trim(),
      if (id == 'email_intake') 'mailbox': _mailboxController.text.trim().isEmpty ? 'INBOX' : _mailboxController.text.trim(),
      if (id == 'watched_folder') 'pollIntervalSeconds': interval,
      if (id == 'ftp' || id == 'email_intake') 'pollIntervalMinutes': interval,
      'enabled': _enabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.integration.name}'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              if (!_isIntakeConnector && !_isAd && !_isSms) ...[
                TextField(controller: _endpointController, decoration: const InputDecoration(labelText: 'Endpoint')),
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
                      Expanded(flex: 2, child: TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Host'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _portController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  Text(
                    'Password is set via the backend .env file (${widget.integration.id == 'ftp' ? 'FTP_INTAKE_PASSWORD' : 'IMAP_INTAKE_PASSWORD'}), not here.',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.integration.id == 'watched_folder')
                  TextField(controller: _pathController, decoration: const InputDecoration(labelText: 'Subfolder (blank = root intake directory)')),
                if (widget.integration.id == 'ftp')
                  TextField(controller: _pathController, decoration: const InputDecoration(labelText: 'Remote path')),
                if (widget.integration.id == 'email_intake')
                  TextField(controller: _mailboxController, decoration: const InputDecoration(labelText: 'Mailbox')),
                const SizedBox(height: 12),
                TextField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: widget.integration.id == 'watched_folder' ? 'Poll interval (seconds)' : 'Poll interval (minutes)'),
                ),
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
                TextField(controller: _adUrlController, decoration: const InputDecoration(labelText: 'URL (e.g. ldaps://dc01.example.local:636)')),
                const SizedBox(height: 12),
                TextField(controller: _adBindDnController, decoration: const InputDecoration(labelText: 'Service account bind DN')),
                const SizedBox(height: 12),
                const Text(
                  'Bind password is set via the backend .env file (AD_BIND_PASSWORD), not here.',
                  style: TextStyle(fontSize: 11.5),
                ),
                const SizedBox(height: 12),
                TextField(controller: _adSearchBaseController, decoration: const InputDecoration(labelText: 'Search base (e.g. dc=example,dc=local)')),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _status,
            endpoint: _isAd ? _adUrlController.text.trim() : _endpointController.text.trim(),
            configJson: _isIntakeConnector
                ? _buildConfigJson()
                : (_isAd ? _buildAdConfigJson() : (_isSms ? _buildSmsConfigJson() : null)),
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
