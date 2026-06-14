import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../document/document_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchHit> _hits = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;
  bool _grouped = true;

  static const _suggestions = [
    'how do I stay focused',
    'fighting distraction',
    'managing my energy',
    'where ideas come from',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _run([String? q]) async {
    final query = (q ?? _controller.text).trim();
    if (query.isEmpty) return;
    if (q != null) {
      _controller.text = q;
      _controller.selection =
          TextSelection.collapsed(offset: q.length);
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final hits = await ref.read(apiClientProvider).search(query);
      setState(() => _hits = hits);
    } on ApiException catch (e) {
      setState(() => _error = 'Search failed (${e.statusCode})');
    } catch (_) {
      setState(() => _error = 'Backend unreachable');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;
    final sem = _hits.where((h) => h.matchedSemantically).toList();
    final kw =
        _hits.where((h) => !h.matchedSemantically && h.matchedKeyword).toList();

    final w = MediaQuery.of(context).size.width;
    final compact = w < 480;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 20, compact ? 24 : 36, compact ? 14 : 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Mg.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Mg.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Mg.ink.withValues(alpha: 0.03),
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: Mg.ink.withValues(alpha: 0.14),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
                        spreadRadius: -26,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 18),
                        child: Icon(Icons.search,
                            size: 19, color: Mg.muted1),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _run,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                              fontSize: 17, color: Mg.ink),
                          decoration: InputDecoration(
                            hintText: compact
                                ? 'Search by meaning…'
                                : 'Search by meaning… e.g. how do I stay focused',
                            hintStyle: TextStyle(
                                color: Mg.muted2, fontSize: compact ? 15 : 17),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                          ),
                        ),
                      ),
                      if (hasQuery)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() {
                                _hits = [];
                                _searched = false;
                                _error = null;
                              });
                              _focusNode.requestFocus();
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                  color: Mg.tray,
                                  shape: BoxShape.circle),
                              child: const Center(
                                  child: Text('✕',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Mg.muted1))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Result meta row
                if (_searched && !_loading && _error == null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${_hits.length} ${_hits.length == 1 ? 'note' : 'notes'}',
                        style: const TextStyle(
                            fontSize: 13, color: Mg.muted1),
                      ),
                      const Spacer(),
                      _SegControl(
                        grouped: _grouped,
                        onGrouped: (v) =>
                            setState(() => _grouped = v),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // States
                if (_loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Mg.muted1)))
                else if (!_searched)
                  _SearchHint(onSuggestion: _run,
                      suggestions: _suggestions)
                else if (_hits.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Nothing matched "${_controller.text}".',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Mg.muted1),
                        ),
                        const SizedBox(height: 6),
                        const Text('Try fewer or different words.',
                            style: TextStyle(
                                fontSize: 13.5, color: Mg.muted2)),
                      ],
                    ),
                  )
                else if (_grouped)
                  _GroupedResults(sem: sem, kw: kw)
                else
                  _RankedResults(hits: _hits),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegControl extends StatelessWidget {
  final bool grouped;
  final void Function(bool) onGrouped;

  const _SegControl({required this.grouped, required this.onGrouped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Mg.tray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Mg.trayBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegBtn(
              label: 'Grouped',
              active: grouped,
              onTap: () => onGrouped(true)),
          _SegBtn(
              label: 'Ranked',
              active: !grouped,
              onTap: () => onGrouped(false)),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegBtn(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: active ? Mg.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Mg.ink.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Mg.blue : Mg.muted1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  final void Function(String) onSuggestion;
  final List<String> suggestions;

  const _SearchHint(
      {required this.onSuggestion, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('Try a question — not just keywords:',
            style: TextStyle(fontSize: 14.5, color: Mg.muted1)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: suggestions
              .map((s) => _SuggChip(
                  label: s, onTap: () => onSuggestion(s)))
              .toList(),
        ),
      ],
    );
  }
}

class _SuggChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggChip({required this.label, required this.onTap});

  @override
  State<_SuggChip> createState() => _SuggChipState();
}

class _SuggChipState extends State<_SuggChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Mg.surface,
            border: Border.all(
                color: _hovered ? Mg.blue : Mg.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
                fontSize: 13.5,
                color: _hovered ? Mg.blue : Mg.ink),
          ),
        ),
      ),
    );
  }
}

class _GroupedResults extends StatelessWidget {
  final List<SearchHit> sem;
  final List<SearchHit> kw;

  const _GroupedResults({required this.sem, required this.kw});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sem.isNotEmpty) ...[
          _SectionHeader(
            label: 'By meaning',
            count: sem.length,
            color: Mg.blue,
            gradientColor: const Color(0xFFDCE4F4),
          ),
          const SizedBox(height: 10),
          ...sem.map((h) => _ResultCard(hit: h)),
          const SizedBox(height: 26),
        ],
        if (kw.isNotEmpty) ...[
          _SectionHeader(
            label: 'Keyword',
            count: kw.length,
            color: Mg.amber,
            gradientColor: const Color(0xFFECDFBF),
          ),
          const SizedBox(height: 10),
          ...kw.map((h) => _ResultCard(hit: h)),
        ],
      ],
    );
  }
}

class _RankedResults extends StatelessWidget {
  final List<SearchHit> hits;
  const _RankedResults({required this.hits});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: hits.map((h) => _ResultCard(hit: h, showDot: true)).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color gradientColor;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.gradientColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.75,
            color: color,
          ),
        ),
        const SizedBox(width: 9),
        Text('$count',
            style: const TextStyle(fontSize: 12, color: Mg.muted3)),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [gradientColor, Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatefulWidget {
  final SearchHit hit;
  final bool showDot;

  const _ResultCard({required this.hit, this.showDot = false});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    final isSem = h.matchedSemantically;
    final color = isSem ? Mg.blue : Mg.amber;
    final tint = isSem ? Mg.blueTint : Mg.amberTint;
    final tintBorder = isSem ? Mg.blueHi : Mg.amberHi;
    final trackColor = isSem
        ? const Color(0xFFE9EEF9)
        : const Color(0xFFF1E8D3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => showNoteDialog(context, h.documentId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(15, 15, 17, 15),
            decoration: BoxDecoration(
              color: Mg.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _hovered
                      ? (isSem
                          ? const Color(0xFFC9D6EF)
                          : const Color(0xFFECDCB4))
                      : Mg.border),
              boxShadow: [
                BoxShadow(
                    color: Mg.ink.withValues(alpha: 0.02),
                    offset: const Offset(0, 1))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showDot) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 7, right: 14),
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              h.title,
                              style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: Mg.ink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: isSem ? 'semantic' : 'keyword',
                            color: color,
                            tint: tint,
                            tintBorder: tintBorder,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.snippet,
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: Mg.muted1,
                            height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      h.score.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 46 * h.score.clamp(0.0, 1.0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color tint;
  final Color tintBorder;

  const _Badge({
    required this.label,
    required this.color,
    required this.tint,
    required this.tintBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tint,
        border: Border.all(color: tintBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.44,
          color: color,
        ),
      ),
    );
  }
}
