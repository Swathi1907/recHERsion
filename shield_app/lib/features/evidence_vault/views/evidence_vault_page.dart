import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/evidence_item.dart';
import '../repositories/api_evidence_repository.dart';
import '../viewmodels/evidence_vault_viewmodel.dart';
import '../widgets/evidence_item_card.dart';

class EvidenceVaultPage extends StatefulWidget {
  const EvidenceVaultPage({super.key});

  @override
  State<EvidenceVaultPage> createState() => _EvidenceVaultPageState();
}

class _EvidenceVaultPageState extends State<EvidenceVaultPage> {
  static const bg = Color(0xFF130B20);
  static const panel = Color(0xFF211532);
  static const violet = Color(0xFF8955E8);
  static const muted = Color(0xFFB9A9D0);
  static const border = Color(0xFF493263);

  late final EvidenceVaultViewModel _viewModel;

 
@override
void initState() {
  super.initState();

  debugPrint('EVIDENCE: Initializing API repository');

  _viewModel = EvidenceVaultViewModel(
    ApiEvidenceRepository(
      baseUrl: 'http://172.22.21.45:3000',
    ),
  );

  debugPrint('EVIDENCE: Loading saved records');
  _viewModel.loadEvidence();
}

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

final ImagePicker _imagePicker = ImagePicker();
bool _isUploadingPhoto = false;

Future<void> _capturePhoto() async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: panel,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
            title: const Text(
              'Take a photo',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () =>
                Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: Colors.white,
            ),
            title: const Text(
              'Choose from gallery',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () =>
                Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null || !mounted) return;

  try {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    await _viewModel.uploadEvidenceFile(
      filePath: image.path,
      title: 'Photo evidence ${DateTime.now().toIso8601String()}',
      type: EvidenceType.photo,
    );

    if (mounted) {
      _showMessage('Photo uploaded successfully.');
    }
  } catch (error) {
    if (mounted) {
      _showMessage('Photo upload failed: $error');
    }
  } finally {
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
    }
  }
}


  Future<void> _showNoteDialog() async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'Add note',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: muted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _viewModel.addNote(
                    titleController.text,
                    noteController.text,
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (mounted) {
                    _showMessage(
                      'Note saved successfully.',
                    );
                  }
                } on ArgumentError catch (error) {
                  if (mounted) {
                    _showMessage(error.message?.toString() ?? 'Invalid note.');
                  }
                } catch (_) {
                  if (mounted) _showMessage('Could not add note.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      titleController.dispose();
      noteController.dispose();
    }
  }

  Future<void> _showCasePackPreview() async {
    final preview = _viewModel.buildCasePackPreview();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text(
          'Case pack preview',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              preview,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Evidence vault',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence vault',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep incident records together',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _captureButton(
                              Icons.mic_rounded,
                              'Audio',
                              () => _showMessage(
                                'Audio capture is not connected yet.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _captureButton(
                              Icons.videocam_rounded,
                              'Video',
                              () => _showMessage(
                                'Video capture is not connected yet.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child:_captureButton(
  Icons.photo_camera_rounded,
  _isUploadingPhoto ? 'Uploading...' : 'Photo',
  _isUploadingPhoto ? () {} : _capturePhoto,
),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _captureButton(
                              Icons.description_rounded,
                              'Note',
                              _showNoteDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1A40),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disguise mode',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Calculator appearance · UI demo',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _viewModel.disguiseMode,
                              activeThumbColor: violet,
                              onChanged: _viewModel.toggleDisguiseMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Saved evidence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '(${_viewModel.items.length})',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_viewModel.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: violet),
                    ),
                  )
                else if (_viewModel.errorMessage != null)
                  Column(
                    children: [
                      Text(
                        _viewModel.errorMessage!,
                        style: const TextStyle(color: muted),
                      ),
                      TextButton(
                        onPressed: _viewModel.loadEvidence,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else if (_viewModel.items.isEmpty)
                  const Text(
                    'No evidence saved yet.',
                    style: TextStyle(color: muted),
                  )
                else
                  ..._viewModel.items.map(
                    (item) => EvidenceItemCard(item: item),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showCasePackPreview,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text(
                      'Generate case pack for police / lawyer / NGO',
                      textAlign: TextAlign.center,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0714),
                      foregroundColor: const Color(0xFFB58BFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(color: border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                'Evidence is stored in your account. File capture and export '
'are not connected yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: violet.withValues(alpha: 0.18),
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 2) return;
          _showMessage(
            '${['Home', 'Route', 'Vault', 'Circle', 'Shield'][index]} '
            'navigation has not been connected on this screen.',
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline_rounded),
            selectedIcon: Icon(Icons.lock_rounded),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Circle',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            label: 'Shield',
          ),
        ],
      ),
    );
  }

  Widget _captureButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 43,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7040C8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
