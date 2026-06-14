import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../document/document_screen.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    final w = MediaQuery.of(context).size.width;
    final compact = w < 480;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 20, compact ? 28 : 40, compact ? 14 : 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'All notes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                        color: Mg.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    notes.when(
                      data: (items) => Text(
                        '${items.length} ${items.length == 1 ? 'note' : 'notes'}',
                        style: const TextStyle(
                            fontSize: 13, color: Mg.muted2),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                notes.when(
                  data: (items) => items.isEmpty
                      ? const _EmptyState()
                      : Column(
                          children: items
                              .map((n) => _NoteCard(note: n))
                              .toList(),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('Failed to load: $e',
                          style:
                              const TextStyle(color: Mg.muted1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text('No notes yet.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Mg.muted1)),
          SizedBox(height: 6),
          Text('Capture a thought and it will show up here.',
              style: TextStyle(fontSize: 13.5, color: Mg.muted2)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final NoteItem note;
  const _NoteCard({required this.note});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => showNoteDialog(context, n.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
            decoration: BoxDecoration(
              color: Mg.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _hovered
                      ? const Color(0xFFD8CDB6)
                      : Mg.border),
              boxShadow: [
                BoxShadow(
                  color: Mg.ink.withValues(alpha: 0.02),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Mg.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _ago(n.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Mg.muted3),
                    ),
                  ],
                ),
                if (n.preview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    n.preview,
                    style: const TextStyle(
                        fontSize: 13.5, color: Mg.muted1, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (n.tags.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        n.tags.map((t) => _NoteTag(t)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: Mg.tagBg,
        border: Border.all(color: Mg.tagBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(fontSize: 11.5, color: Mg.muted1),
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
