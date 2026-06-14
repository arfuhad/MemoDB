import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../document/document_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _saving = false;
  bool _generating = false;
  bool _titleManuallyEdited = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still up?';
    if (h < 12) return 'Good morning.';
    if (h < 18) return 'Good afternoon.';
    return 'Good evening.';
  }

  Future<void> _generateTitle() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _generating || _titleManuallyEdited) return;
    setState(() => _generating = true);
    try {
      final title = await ref.read(apiClientProvider).suggestTitle(text);
      if (mounted) _titleController.text = title;
    } catch (_) {
      // silently ignore — user can still type a title manually
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _onBodyChanged(String value) {
    setState(() {});
    if (_titleManuallyEdited) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _controller.text.trim().isNotEmpty && _titleController.text.isEmpty) {
        _generateTitle();
      }
    });
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

  void _removeTag(int i) => setState(() => _tags.removeAt(i));

  void _onTagChanged(String v) {
    if (v.endsWith(',') || v.endsWith(' ')) {
      _addTag(v.substring(0, v.length - 1));
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    final pending = _tagController.text.trim().replaceAll(',', '');
    final tags = List<String>.from(_tags);
    if (pending.isNotEmpty) {
      final t = pending.replaceAll(RegExp(r'^#+'), '').toLowerCase();
      if (t.isNotEmpty && !tags.contains(t)) tags.add(t);
    }
    setState(() => _saving = true);
    try {
      final titleText = _titleController.text.trim();
      await ref.read(apiClientProvider).capture(
            text,
            title: titleText.isEmpty ? null : titleText,
            tags: tags.isEmpty ? ['inbox'] : tags,
          );
      _titleManuallyEdited = false;
      _controller.clear();
      _titleController.clear();
      _tagController.clear();
      setState(() => _tags.clear());
      ref.invalidate(notesProvider);
      if (!mounted) return;
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration:
                    const BoxDecoration(color: Mg.blue, shape: BoxShape.circle),
                child: const Center(
                    child: Text('✓',
                        style:
                            TextStyle(color: Colors.white, fontSize: 10))),
              ),
              const SizedBox(width: 9),
              const Text('Saved to Margin',
                  style: TextStyle(
                      color: Mg.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: Mg.ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          width: 220,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save (${e.statusCode})')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend unreachable')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final charCount = _controller.text.trim().isEmpty
        ? 'Empty'
        : '${_controller.text.trim().length} chars';

    final w = MediaQuery.of(context).size.width;
    final compact = w < 480;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 20, compact ? 28 : 40, compact ? 14 : 20, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: compact ? 24.0 : 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.75,
                    color: Mg.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  compact
                      ? 'Type a thought and find it by meaning.'
                      : 'Type a thought. Save it. Find it later by meaning.',
                  style: TextStyle(fontSize: compact ? 13.5 : 14.5, color: Mg.muted1),
                ),
                const SizedBox(height: 20),

                // Composer card
                Container(
                  decoration: BoxDecoration(
                    color: Mg.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Mg.border),
                    boxShadow: [
                      BoxShadow(
                        color: Mg.ink.withValues(alpha: 0.03),
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: Mg.ink.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                        spreadRadius: -22,
                      ),
                    ],
                  ),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter,
                          meta: true): _save,
                      const SingleActivator(LogicalKeyboardKey.enter,
                          control: true): _save,
                    },
                    child: Column(
                      children: [
                        // Title row
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Mg.divider)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  onChanged: (_) => _titleManuallyEdited = true,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Mg.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Note title…',
                                    hintStyle: TextStyle(
                                        color: Mg.muted3, fontSize: 15),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (hasText) ...[
                                const SizedBox(width: 10),
                                _GenerateBtn(
                                  loading: _generating,
                                  onTap: _generateTitle,
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          maxLines: null,
                          minLines: 5,
                          onChanged: _onBodyChanged,
                          style: const TextStyle(
                              fontSize: 18, height: 1.6, color: Mg.ink),
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: TextStyle(
                                color: Mg.muted3, fontSize: 18),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.fromLTRB(18, 18, 18, 6),
                          ),
                        ),
                        // Tags row
                        Container(
                          padding:
                              const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Mg.divider)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.label_outline,
                                  size: 13, color: Mg.muted1),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    ..._tags.asMap().entries.map((e) =>
                                        _TagChip(
                                          label: e.value,
                                          onRemove: () =>
                                              _removeTag(e.key),
                                        )),
                                    SizedBox(
                                      width: 120,
                                      height: 24,
                                      child: TextField(
                                        controller: _tagController,
                                        onChanged: _onTagChanged,
                                        onSubmitted: (_) => _addTag(),
                                        style: const TextStyle(
                                            fontSize: 13, color: Mg.ink),
                                        decoration: const InputDecoration(
                                          hintText: 'Add tag…',
                                          hintStyle: TextStyle(
                                              color: Mg.muted3,
                                              fontSize: 13),
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
                        // Footer
                        Container(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Mg.divider)),
                          ),
                          child: Row(
                            children: [
                              Text(charCount,
                                  style: const TextStyle(
                                      fontSize: 12, color: Mg.muted2)),
                              const Spacer(),
                              const Text('⌘↵ to save',
                                  style: TextStyle(
                                      fontSize: 12, color: Mg.muted2)),
                              const SizedBox(width: 12),
                              _SaveBtn(
                                enabled: hasText && !_saving,
                                loading: _saving,
                                onTap: _save,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Recent notes
                const Text(
                  'RECENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.96,
                    color: Mg.muted2,
                  ),
                ),
                const SizedBox(height: 12),
                _RecentNotes(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SaveBtn(
      {required this.enabled,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? Mg.blue : Mg.tray,
            borderRadius: BorderRadius.circular(9),
          ),
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white)),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Mg.surface : Mg.muted3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const _TagChip({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 9, top: 2, bottom: 2, right: onRemove != null ? 4 : 9),
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
                  fontSize: 12,
                  color: Mg.blue,
                  fontWeight: FontWeight.w600)),
          if (onRemove != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                    color: Mg.blueHi, shape: BoxShape.circle),
                child: const Center(
                    child: Text('✕',
                        style:
                            TextStyle(fontSize: 9, color: Mg.blue))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentNotes extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    return notes.when(
      data: (items) {
        if (items.isEmpty) {
          return const Text('No notes yet.',
              style: TextStyle(fontSize: 14, color: Mg.muted2));
        }
        return Column(
          children:
              items.take(6).map((n) => _RecentRow(note: n)).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RecentRow extends StatefulWidget {
  final NoteItem note;
  const _RecentRow({required this.note});

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => showNoteDialog(context, widget.note.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFAF6EC)
                : Colors.transparent,
            border: const Border(
                bottom: BorderSide(color: Mg.border)),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.note.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Mg.ink)),
                    if (widget.note.preview.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          widget.note.preview,
                          style: const TextStyle(
                              fontSize: 13.5, color: Mg.muted1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(_ago(widget.note.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: Mg.muted3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GenerateBtn({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Mg.blueTint,
            border: Border.all(color: Mg.blueHi),
            borderRadius: BorderRadius.circular(8),
          ),
          child: loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Mg.blue),
                  ),
                )
              : const Text(
                  '✦ Generate',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Mg.blue,
                  ),
                ),
        ),
      ),
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
