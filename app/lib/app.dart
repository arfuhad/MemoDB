import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/capture/capture_screen.dart';
import 'features/profile/profile_dialog.dart';
import 'features/notes/notes_screen.dart';
import 'features/search/search_screen.dart';

class PkmApp extends StatelessWidget {
  const PkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margin',
      debugShowCheckedModeBanner: false,
      theme: Mg.theme(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(healthProvider).valueOrNull ?? false;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            setState(() => _tab = 1),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            setState(() => _tab = 1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Mg.paper,
          body: Column(
            children: [
              _MarginHeader(
                tab: _tab,
                online: online,
                onTab: (i) => setState(() => _tab = i),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: const [
                    CaptureScreen(),
                    SearchScreen(),
                    NotesScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarginHeader extends ConsumerWidget {
  final int tab;
  final bool online;
  final void Function(int) onTab;

  const _MarginHeader({
    required this.tab,
    required this.online,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      // <480: stack tab pill on a second row
      // <580: collapse status pill to dot-only
      final stacked = w < 480;
      final hideLabel = w < 580;
      final hPad = w < 480 ? 14.0 : 24.0;

      final logoMark = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Mg.ink,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: Mg.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

      const wordmark = Text(
        'Margin',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.34,
          color: Mg.ink,
        ),
      );

      final avatar = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showProfileDialog(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Mg.ink,
              shape: BoxShape.circle,
              border: Border.all(color: Mg.trayBorder),
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Mg.paper,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      );

      final statusDot = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: online ? Mg.green : Mg.muted3,
          shape: BoxShape.circle,
          boxShadow: online
              ? [BoxShadow(color: Mg.green.withValues(alpha: 0.18), blurRadius: 0, spreadRadius: 3)]
              : null,
        ),
      );

      final statusWidget = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.refresh(healthProvider),
          child: hideLabel
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Mg.trayBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(child: statusDot),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Mg.trayBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      statusDot,
                      const SizedBox(width: 8),
                      Text(
                        online ? 'Connected' : 'Offline',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Mg.ink,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

      final tabPill = _TabPill(tab: tab, onTab: onTab, compact: stacked);

      final topRow = Row(
        children: [
          logoMark,
          const SizedBox(width: 9),
          wordmark,
          if (!stacked) ...[
            const SizedBox(width: 16),
            tabPill,
          ],
          const Spacer(),
          statusWidget,
          const SizedBox(width: 10),
          avatar,
        ],
      );

      return Container(
        padding: EdgeInsets.fromLTRB(hPad, stacked ? 10 : 14, hPad, stacked ? 8 : 14),
        decoration: const BoxDecoration(
          color: Mg.paper,
          border: Border(bottom: BorderSide(color: Mg.trayBorder)),
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topRow,
                  const SizedBox(height: 10),
                  Center(child: tabPill),
                ],
              )
            : topRow,
      );
    });
  }
}

class _TabPill extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  final bool compact;

  const _TabPill({required this.tab, required this.onTab, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Mg.tray,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Mg.trayBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabBtn(label: 'Capture', index: 0, current: tab, onTap: onTab, compact: compact),
          _TabBtn(label: 'Search', index: 1, current: tab, onTap: onTab, compact: compact),
          _TabBtn(label: 'Notes', index: 2, current: tab, onTap: onTab, compact: compact),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;
  final bool compact;

  const _TabBtn({
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15, vertical: compact ? 5 : 6),
          decoration: BoxDecoration(
            color: active ? Mg.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Mg.ink.withValues(alpha:0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: active ? Mg.ink : Mg.muted1,
            ),
          ),
        ),
      ),
    );
  }
}
