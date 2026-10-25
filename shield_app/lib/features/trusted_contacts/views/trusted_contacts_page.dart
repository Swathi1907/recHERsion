
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trusted_contact.dart';
import '../repositories/api_trusted_contacts_repository.dart';

class TrustedContactsPage extends StatefulWidget {
  const TrustedContactsPage({super.key});

  static const baseUrl = 'http://172.22.21.45:3000';

  @override
  State<TrustedContactsPage> createState() => _TrustedContactsPageState();
}

class _TrustedContactsPageState extends State<TrustedContactsPage> {
  late final ApiTrustedContactsRepository _repository;

  List<TrustedContact> _contacts = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ApiTrustedContactsRepository(
      baseUrl: TrustedContactsPage.baseUrl,
    );
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final contacts = await _repository.getContacts();
      if (!mounted) return;

      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addContact() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add trusted contact'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a name'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    return phone.length < 7 || phone.length > 20
                        ? 'Enter a valid phone number'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    hintText: 'e.g. Friend, Parent, Sibling',
                    prefixIcon: Icon(Icons.favorite_border),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a relationship'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save contact'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      nameController.dispose();
      phoneController.dispose();
      relationshipController.dispose();
      return;
    }

    setState(() => _saving = true);

    try {
      final contact = await _repository.addContact(
        name: nameController.text,
        phone: phoneController.text,
        relationship: relationshipController.text,
      );

      if (!mounted) return;

      setState(() {
        _contacts.insert(0, contact);
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trusted contact added successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add contact: $error')),
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      relationshipController.dispose();
    }
  }

  Future<void> _deleteContact(TrustedContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove contact?'),
        content: Text('Remove ${contact.name} from your trusted contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteContact(contact.id);
      if (!mounted) return;

      setState(() {
        _contacts.removeWhere((item) => item.id == contact.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact removed')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove contact: $error')),
      );
    }
  }

  Future<void> _callContact(TrustedContact contact) async {
    final uri = Uri(scheme: 'tel', path: contact.phone);

    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app')),
      );
    }
  }

  Future<void> _messageContact(TrustedContact contact) async {
    final uri = Uri(scheme: 'sms', path: contact.phone);

    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the messaging app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF31D6C5);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed: _loading ? null : _loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addContact,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContacts,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: accent, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'Your safety circle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add people you trust so you can reach them quickly '
                      'when you need support.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Saved contacts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text('${_contacts.length}'),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 36),
                        const SizedBox(height: 12),
                        const Text('Could not load your contacts'),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadContacts,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 56),
                      SizedBox(height: 12),
                      Text(
                        'No trusted contacts yet',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use Add contact to create your safety circle.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._contacts.map(
                  (contact) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: accent.withValues(alpha: 0.15),
                                child: Text(
                                  contact.name.trim().isNotEmpty
                                      ? contact.name.trim()[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(contact.relationship),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.phone,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove contact',
                                onPressed: () => _deleteContact(contact),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _callContact(contact),
                                  icon: const Icon(Icons.call_outlined),
                                  label: const Text('Call'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _messageContact(contact),
                                  icon: const Icon(Icons.message_outlined),
                                  label: const Text('Message'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}
