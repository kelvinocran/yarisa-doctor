import 'package:flutter/material.dart';
import 'package:yarisa_doctor/services/active_call_controller.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Global floating chip: on-call / rejoin / peer waiting.
class ActiveCallBanner extends StatefulWidget {
  const ActiveCallBanner({super.key});

  @override
  State<ActiveCallBanner> createState() => _ActiveCallBannerState();
}

class _ActiveCallBannerState extends State<ActiveCallBanner> {
  final _controller = ActiveCallController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (!c.showBanner) return const SizedBox.shrink();
    final inCall = c.status == ActiveCallStatus.inCall;
    final waiting = c.status == ActiveCallStatus.peerWaiting;
    final color = inCall
        ? DoctorUi.primary
        : waiting
            ? Colors.teal.shade700
            : Colors.orange.shade700;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(28),
          color: color,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => c.rejoin(),
            onLongPress: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('End call?'),
                  content: const Text(
                    'This ends the call for you. Long-press confirms end; tap rejoins.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('End call'),
                    ),
                  ],
                ),
              );
              if (ok == true) await c.hangUp(reason: 'ended');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    inCall
                        ? Icons.call
                        : waiting
                            ? Icons.call_received
                            : Icons.call_missed_outgoing,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      c.bannerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Provides its own [Overlay] so the call chip can float without
/// OverlayPortal (MaterialApp.builder has no Overlay ancestor) and
/// without a Stack around the navigator (that crashes on route changes).
class ActiveCallOverlay extends StatefulWidget {
  const ActiveCallOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  late final OverlayEntry _root;

  @override
  void initState() {
    super.initState();
    _root = OverlayEntry(
      opaque: true,
      maintainState: true,
      builder: (context) => _CallBannerHost(child: widget.child),
    );
  }

  @override
  void didUpdateWidget(covariant ActiveCallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _root.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_root]);
  }
}

class _CallBannerHost extends StatefulWidget {
  const _CallBannerHost({required this.child});

  final Widget child;

  @override
  State<_CallBannerHost> createState() => _CallBannerHostState();
}

class _CallBannerHostState extends State<_CallBannerHost> {
  OverlayEntry? _banner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _banner != null) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      _banner = OverlayEntry(
        builder: (context) => const Align(
          alignment: Alignment.topCenter,
          child: ActiveCallBanner(),
        ),
      );
      overlay.insert(_banner!);
    });
  }

  @override
  void dispose() {
    _banner?.remove();
    _banner = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
