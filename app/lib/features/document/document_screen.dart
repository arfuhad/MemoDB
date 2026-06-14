import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

final documentProvider =
    FutureProvider.family<DocumentDetail, String>((ref, id) async {
  return ref.watch(apiClientProvider).document(id);
});

Future<void> showNoteDialog(BuildContext context, String documentId) {
  return showDialog(
    context: context,
    barrierColor: Mg.ink.withValues(alpha: 0.34),
    builder: (_) => _NoteModal(documentId: documentId),
  );
}

// ── Modal shell ──────────────────────────────────────────────────────────────

class _NoteModal extends ConsumerStatefulWidget {
  final String documentId;
  const _NoteModal({required this.documentId});

  @override
  ConsumerState<_NoteModal> createState() => _NoteModalState();
}

class _NoteModalState extends ConsumerState<_NoteModal> {
  bool _editing = false;
  bool _saving = false;
  bool _confirmDelete = false;
  bool _deleting = false;
  bool _initialized = false;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _initFromDoc(DocumentDetail doc) {
    if (_initialized) return;
    _titleController.text = doc.title;
    _bodyController.text = doc.bodyText;
    _tags = List.from(doc.tags);
    _initialized = true;
  }

  void _addTag([String? raw]) {
    final tag = (raw ?? _tagController.text)
        .trim()
        .replaceAll(RegExp(r'^#+'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    if (tag.isEmpty || tag.length > 24) return;
    if (!_tags.contains(tag)) setState(() => _tags.add(tag));
    _tagController.clear();
  }

  void _onTagChanged(String v) {
    if (v.endsWith(',') || v.endsWith(' ')) {
      _addTag(v.substring(0, v.length - 1));
    }
  }

  Future<void> _save() async {
    final text = _bodyController.text.trim();
    if (text.isEmpty || _saving) return;
    // Flush any partially-typed tag
    final pending = _tagController.text.trim().replaceAll(',', '');
    final tags = List<String>.from(_tags);
    if (pending.isNotEmpty) {
      final t = pending.replaceAll(RegExp(r'^#+'), '').toLowerCase();
      if (t.isNotEmpty && !tags.contains(t)) tags.add(t);
    }
    setState(() => _saving = true);
    try {
      final titleText = _titleController.text.trim();
      await ref.read(apiClientProvider).updateDocument(
            widget.documentId,
            text,
            title: titleText.isEmpty ? null : titleText,
            tags: tags,
          );
      ref.invalidate(documentProvider(widget.documentId));
      ref.invalidate(notesProvider);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _initialized = false;
        _tags = tags;
        _tagController.clear();
      });
    } catch (_) {
      // leave edit mode open so user can retry
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(apiClientProvider).deleteDocument(widget.documentId);
      ref.invalidate(notesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _deleting = false; _confirmDelete = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(documentProvider(widget.documentId));
    final w = MediaQuery.of(context).size.width;
    final compact = w < 480;

    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Container(
            margin: EdgeInsets.all(compact ? 12 : 20),
            decoration: BoxDecoration(
              color: Mg.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Mg.border),
              boxShadow: [
                BoxShadow(
                  color: Mg.ink.withValues(alpha: 0.45),
                  blurRadius: 80,
                  offset: const Offset(0, 30),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: async.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Error: $e',
                      style: const TextStyle(color: Mg.muted1)),
                ),
                data: (doc) {
                  _initFromDoc(doc);
                  return _editing
                      ? _EditShell(
                          doc: doc,
                          compact: compact,
                          titleController: _titleController,
                          bodyController: _bodyController,
                          tagController: _tagController,
                          tags: _tags,
                          saving: _saving,
                          onAddTag: _addTag,
                          onTagChanged: _onTagChanged,
                          onRemoveTag: (i) => setState(() => _tags.removeAt(i)),
                          onSave: _save,
                          onCancel: () => setState(() {
                            _editing = false;
                            _initialized = false;
                          }),
                          onClose: () => Navigator.of(context).pop(),
                        )
                      : _ViewShell(
                          doc: doc,
                          compact: compact,
                          confirmDelete: _confirmDelete,
                          deleting: _deleting,
                          onEdit: () => setState(() {
                            _editing = true;
                            _initFromDoc(doc);
                          }),
                          onRequestDelete: () =>
                              setState(() => _confirmDelete = true),
                          onCancelDelete: () =>
                              setState(() => _confirmDelete = false),
                          onConfirmDelete: _delete,
                          onClose: () => Navigator.of(context).pop(),
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── View mode ────────────────────────────────────────────────────────────────

class _ViewShell extends StatelessWidget {
  final DocumentDetail doc;
  final bool compact;
  final bool confirmDelete;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onRequestDelete;
  final VoidCallback onCancelDelete;
  final VoidCallback onConfirmDelete;
  final VoidCallback onClose;

  const _ViewShell({
    required this.doc,
    required this.compact,
    required this.confirmDelete,
    required this.deleting,
    required this.onEdit,
    required this.onRequestDelete,
    required this.onCancelDelete,
    required this.onConfirmDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 14, 12, 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Mg.divider))),
          child: Row(
            children: [
              if (confirmDelete) ...[
                const Text('Delete this note?',
                    style: TextStyle(fontSize: 12, color: Mg.red)),
                const Spacer(),
                _HeaderBtn('Cancel', onTap: onCancelDelete),
                const SizedBox(width: 8),
                _HeaderBtn('Delete', danger: true, loading: deleting, onTap: onConfirmDelete),
              ] else ...[
                Text('Captured ${_ago(doc.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Mg.muted3)),
                const Spacer(),
                _HeaderBtn('Edit', onTap: onEdit),
                const SizedBox(width: 8),
                _HeaderBtn('Delete', danger: true, onTap: onRequestDelete),
                const SizedBox(width: 8),
                _HeaderBtn('Close', onTap: onClose),
              ],
            ],
          ),
        ),
        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                compact ? 20 : 44, 26, compact ? 20 : 44, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: TextStyle(
                    fontSize: compact ? 24.0 : 32.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.15,
                    color: Mg.ink,
                  ),
                ),
                if (doc.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: doc.tags.map((t) => _NoteTag(t)).toList(),
                  ),
                ],
                const SizedBox(height: 22),
                SelectableText(
                  doc.bodyText,
                  style: const TextStyle(
                      fontSize: 17, height: 1.72, color: Color(0xFF3A352E)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Edit mode ────────────────────────────────────────────────────────────────

class _EditShell extends StatelessWidget {
  final DocumentDetail doc;
  final bool compact;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final List<String> tags;
  final bool saving;
  final void Function([String?]) onAddTag;
  final void Function(String) onTagChanged;
  final void Function(int) onRemoveTag;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  const _EditShell({
    required this.doc,
    required this.compact,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.tags,
    required this.saving,
    required this.onAddTag,
    required this.onTagChanged,
    required this.onRemoveTag,
    required this.onSave,
    required this.onCancel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 14, 12, 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Mg.divider))),
          child: Row(
            children: [
              const Text('Editing',
                  style: TextStyle(fontSize: 12, color: Mg.muted3)),
              const Spacer(),
              _HeaderBtn('Cancel', onTap: onCancel),
              const SizedBox(width: 8),
              _HeaderBtn('Save', primary: true, loading: saving, onTap: onSave),
              const SizedBox(width: 8),
              _HeaderBtn('Close', onTap: onClose),
            ],
          ),
        ),
        // Body editor
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                compact ? 16 : 36, 20, compact ? 16 : 36, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                      fontSize: 24.0, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: Mg.ink),
                  decoration: const InputDecoration(
                    hintText: 'Note title…',
                    hintStyle: TextStyle(color: Mg.muted3),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  autofocus: true,
                  maxLines: null,
                  minLines: 8,
                  style: const TextStyle(
                      fontSize: 16, height: 1.65, color: Mg.ink),
                  decoration: const InputDecoration(
                    hintText: 'Note content…',
                    hintStyle: TextStyle(color: Mg.muted3),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                // Tags row
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Mg.divider))),
                  child: Row(
                    children: [
                      const Icon(Icons.label_outline,
                          size: 13, color: Mg.muted1),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...tags.asMap().entries.map(
                                  (e) => _EditTagChip(
                                    label: e.value,
                                    onRemove: () => onRemoveTag(e.key),
                                  ),
                                ),
                            SizedBox(
                              width: 120,
                              height: 24,
                              child: TextField(
                                controller: tagController,
                                onChanged: onTagChanged,
                                onSubmitted: (_) => onAddTag(),
                                style: const TextStyle(
                                    fontSize: 13, color: Mg.ink),
                                decoration: const InputDecoration(
                                  hintText: 'Add tag…',
                                  hintStyle:
                                      TextStyle(color: Mg.muted3, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final bool loading;

  const _HeaderBtn(
    this.label, {
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (primary) {
      bg = Mg.blue;
      fg = Mg.surface;
    } else if (danger) {
      bg = Mg.red.withValues(alpha: 0.09);
      fg = Mg.red;
    } else {
      bg = const Color(0xFFF1E9DA);
      fg = Mg.muted1;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: loading
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(fg)),
                )
              : Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fg)),
        ),
      ),
    );
  }
}

class _EditTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _EditTagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 9, top: 2, bottom: 2, right: 4),
      decoration: BoxDecoration(
        color: Mg.blueTint,
        border: Border.all(color: Mg.blueHi),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$label',
              style: const TextStyle(
                  fontSize: 12, color: Mg.blue, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                  color: Mg.blueHi, shape: BoxShape.circle),
              child: const Center(
                  child:
                      Text('✕', style: TextStyle(fontSize: 9, color: Mg.blue))),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTag extends StatelessWidget {
  final String tag;
  const _NoteTag(this.tag);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: Mg.tagBg,
        border: Border.all(color: Mg.tagBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('#$tag',
          style: const TextStyle(fontSize: 12, color: Mg.muted1)),
    );
  }
}

String _ago(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
