import 'package:flutter/material.dart';
import 'package:yarisa_doctor/services/active_call_controller.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Floating chip shown while on a call / able to rejoin.
class ActiveCallBanner extends StatelessWidget {
  const ActiveCallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ActiveCallController.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (c.status == ActiveCallStatus.idle) {
          return const SizedBox.shrink();
        }
        final inCall = c.status == ActiveCallStatus.inCall;
        final name = c.peerName?.trim().isNotEmpty == true
            ? c.peerName!
            : 'Patient';
        final label = inCall
            ? 'On call · $name · ${c.elapsedLabel}'
            : 'Rejoin call · $name';
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                color: inCall ? DoctorUi.primary : Colors.orange.shade700,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    if (inCall) {
                      // Already in meeting UI; rejoin if needed.
                      await c.rejoin();
                    } else {
                      await c.rejoin();
                    }
                  },
                  onLongPress: () async {
                    await c.hangUp(reason: 'ended');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          inCall ? Icons.call : Icons.call_missed_outgoing,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
          ),
        );
      },
    );
  }
}
