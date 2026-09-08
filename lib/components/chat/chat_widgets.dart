import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class ChatThreadTile extends StatelessWidget {
  const ChatThreadTile({
    super.key,
    required this.name,
    required this.image,
    required this.preview,
    required this.onTap,
    this.timestamp,
    this.isOnline = false,
    this.isUnread = false,
    this.unreadCount = 0,
  });

  final String name;
  final String image;
  final String preview;
  final DateTime? timestamp;
  final VoidCallback onTap;
  final bool isOnline;
  final bool isUnread;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DoctorCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isUnread ? DoctorUi.primary.withValues(alpha: .06) : null,
      borderColor:
          isUnread ? DoctorUi.primary.withValues(alpha: .28) : null,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleImage(size: 48, image: image),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: DoctorUi.surface, width: 2),
                    ),
                  ),
                ),
              if (isUnread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: DoctorUi.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _formatTime(timestamp!),
                        style: theme.bodySmall?.copyWith(
                          color: isUnread ? DoctorUi.primary : DoctorUi.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isOnline) ...[
                      Text(
                        'Online',
                        style: theme.bodySmall?.copyWith(
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: theme.bodySmall?.copyWith(color: DoctorUi.muted),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall?.copyWith(
                          color: isUnread
                              ? theme.bodyMedium?.color
                              : DoctorUi.muted,
                          fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, color: DoctorUi.muted, size: 22),
        ],
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return DateFormat.jm().format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat.E().format(local);
    }
    return DateFormat.MMMd().format(local);
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.timestamp,
  });

  final String text;
  final bool isMine;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final bg = isMine ? DoctorUi.primary : DoctorUi.surface;
    final fg = isMine ? Colors.white : null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            border: isMine ? null : Border.all(color: DoctorUi.border),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: theme.bodyMedium?.copyWith(
                  color: fg,
                  height: 1.35,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat.jm().format(timestamp!.toLocal()),
                  style: theme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: .75)
                        : DoctorUi.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: DoctorUi.surface,
        border: Border(top: BorderSide(color: DoctorUi.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a message…',
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: DoctorUi.primary,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(EneftyIcons.send_2_bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
