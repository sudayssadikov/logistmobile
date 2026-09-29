import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../calls/domain/models/call_model.dart';
import '../../../calls/presentation/bloc/call_bloc.dart';
import '../../../calls/presentation/bloc/call_event.dart';
import '../../../shipments/domain/models/shipment_model.dart';
import '../../../shipments/domain/repositories/shipment_repository.dart';
import '../../domain/models/chat_message_model.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_attachment_sheet.dart';
import '../widgets/voice_note_player_widget.dart';

class ChatConversationScreen extends StatefulWidget {
  final String shipmentId;

  const ChatConversationScreen({super.key, required this.shipmentId});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ShipmentModel? _shipment;
  bool _isSearching = false;
  bool _hasText = false;

  final List<String> _quickChips = [
    'chat.chipGps',
    'chat.chipEta',
    'chat.chipLoaded',
    'chat.chipArrived',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(FetchChatMessagesRequested(widget.shipmentId));
    _loadShipmentData();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  Future<void> _loadShipmentData() async {
    try {
      final repo = getIt<IShipmentRepository>();
      final res = await repo.getShipmentById(widget.shipmentId);
      if (res.isSuccess && res.dataOrNull != null && mounted) {
        setState(() {
          _shipment = res.dataOrNull;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({
    String? text,
    MessageType type = MessageType.text,
    VoiceNotePayload? voicePayload,
    MediaAttachment? mediaAttachment,
    LocationPinPayload? locationPayload,
  }) {
    final msg = text ?? _textController.text.trim();
    if (msg.isEmpty && voicePayload == null && mediaAttachment == null && locationPayload == null) return;

    final replying = context.read<ChatBloc>().state.replyingMessage;

    context.read<ChatBloc>().add(
          SendChatMessageSubmitted(
            shipmentId: widget.shipmentId,
            content: msg.isNotEmpty ? msg : (type == MessageType.voiceNote ? 'Ovozli xabar' : 'Hujjat / Fayl'),
            type: type,
            voicePayload: voicePayload,
            mediaAttachment: mediaAttachment,
            locationPayload: locationPayload,
            replyTo: replying,
          ),
        );

    _textController.clear();
    _scrollToBottom();
  }

  void _showReactionSheet(BuildContext context, ChatMessageModel message) {
    final reactions = ['👍', '❤️', '🔥', '🚛', '📦', '⚡'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: reactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<ChatBloc>().add(
                              ToggleMessageReactionRequested(
                                shipmentId: widget.shipmentId,
                                messageId: message.id,
                                emoji: emoji,
                              ),
                            );
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Reply (Iqtibos keltirish)'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatBloc>().add(
                        SetReplyingMessage(
                          ReplySnippet(
                            messageId: message.id,
                            senderName: message.senderName,
                            content: message.content,
                            type: message.type,
                          ),
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Text'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard')),
                  );
                },
              ),
              if (message.isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
                  title: const Text('Delete Message', style: TextStyle(color: AppColors.rose)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<ChatBloc>().add(
                          DeleteChatMessageRequested(
                            shipmentId: widget.shipmentId,
                            messageId: message.id,
                          ),
                        );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatAttachmentSheet(
        onAttachmentSelected: ({
          required String content,
          required MessageType type,
          MediaAttachment? mediaAttachment,
          LocationPinPayload? locationPayload,
        }) {
          _sendMessage(
            text: content,
            type: type,
            mediaAttachment: mediaAttachment,
            locationPayload: locationPayload,
          );
        },
      ),
    );
  }

  void _startCall({
    required CallType type,
    required String receiverId,
    required String receiverName,
  }) {
    context.read<CallBloc>().add(
          StartCallRequested(
            receiverId: receiverId,
            receiverName: receiverName,
            type: type,
            shipmentId: widget.shipmentId,
          ),
        );
    context.push('/calls/active');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.watch<AuthBloc>().state.user;
    final isDriverOrCarrier = currentUser?.role == UserRole.driver || currentUser?.role == UserRole.carrier;

    // Dynamic interlocutor based on user role and shipment
    String interlocutorName;
    String interlocutorSubtitle;
    String interlocutorId;

    if (isDriverOrCarrier) {
      interlocutorName = _shipment?.shipperName.isNotEmpty == true
          ? _shipment!.shipperName
          : 'Zavod / Yuk egasi';
      interlocutorSubtitle = 'online • ${_shipment?.cargoTitle ?? "Yuk buyurtmachisi"}';
      interlocutorId = _shipment?.shipperId ?? 'USR-SHIPPER-01';
    } else {
      interlocutorName = _shipment?.driverName?.isNotEmpty == true
          ? _shipment!.driverName!
          : (_shipment?.carrierName ?? 'Haydovchi / Tashuvchi');
      interlocutorSubtitle = 'online • ${_shipment?.vehiclePlate ?? "Tashuvchi fura"}';
      interlocutorId = _shipment?.carrierId ?? 'USR-DRIVER-01';
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Muloqotdan qidirish...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
                onChanged: (q) {
                  context.read<ChatBloc>().add(SearchMessagesQueryChanged(q));
                },
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isDriverOrCarrier
                        ? AppColors.emerald.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.18),
                    child: Icon(
                      isDriverOrCarrier ? Icons.factory_rounded : Icons.local_shipping_rounded,
                      color: isDriverOrCarrier ? AppColors.emerald : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          interlocutorName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                interlocutorSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  context.read<ChatBloc>().add(const SearchMessagesQueryChanged(''));
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.phone_outlined),
              tooltip: 'Ovozli qo\'ng\'iroq',
              onPressed: () => _startCall(
                type: CallType.audio,
                receiverId: interlocutorId,
                receiverName: interlocutorName,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Video qo\'ng\'iroq',
              onPressed: () => _startCall(
                type: CallType.video,
                receiverId: interlocutorId,
                receiverName: interlocutorName,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Qidirish',
              onPressed: () => setState(() => _isSearching = true),
            ),
          ],
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final messages = state.filteredMessages;

          return Column(
            children: [
              // Message Stream List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.isMine;

                    // System Event Banner
                    if (msg.type == MessageType.systemAlert) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            msg.content.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Dismissible(
                      key: Key('reply_${msg.id}'),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) async {
                        context.read<ChatBloc>().add(
                              SetReplyingMessage(
                                ReplySnippet(
                                  messageId: msg.id,
                                  senderName: msg.senderName,
                                  content: msg.content,
                                  type: msg.type,
                                ),
                              ),
                            );
                        return false;
                      },
                      child: GestureDetector(
                        onLongPress: () => _showReactionSheet(context, msg),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quoted Reply Banner
                                if (msg.replyTo != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.black12 : (isDark ? AppColors.darkSurfaceElevated : Colors.black.withValues(alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border(
                                        left: BorderSide(
                                          color: isMe ? Colors.white : AppColors.primary,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.replyTo!.senderName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isMe ? Colors.white : AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          msg.replyTo!.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Sender Name (for incoming)
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),

                                // Rich Content Payload Rendering
                                if (msg.type == MessageType.voiceNote && msg.voicePayload != null)
                                  VoiceNotePlayerWidget(
                                    voicePayload: msg.voicePayload!,
                                    isMine: isMe,
                                  )
                                else if (msg.type == MessageType.image) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      msg.mediaAttachment?.url ?? 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800',
                                      fit: BoxFit.cover,
                                      height: 160,
                                      width: double.infinity,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    msg.content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMe ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ] else if (msg.type == MessageType.document) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white12 : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isMe ? Colors.white24 : AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.picture_as_pdf_rounded,
                                            color: isMe ? Colors.white : AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.mediaAttachment?.fileName ?? msg.content,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isMe ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                msg.mediaAttachment?.formattedSize ?? '2.4 MB • PDF',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isMe ? Colors.white70 : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (msg.type == MessageType.locationPin && msg.locationPayload != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white12 : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: AppColors.rose, size: 28),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.locationPayload!.title,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isMe ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                ),
                                              ),
                                              Text(
                                                msg.locationPayload!.address,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isMe ? Colors.white70 : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    msg.content.tr(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMe ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 4),

                                // Bottom Message Meta (Time & Delivery Status Ticks)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (msg.isEdited)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Text(
                                          'edited',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: isMe ? Colors.white60 : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      DateFormat('HH:mm').format(msg.timestamp),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isMe ? Colors.white70 : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        msg.status == MessageStatus.read ? Icons.done_all_rounded : Icons.done_rounded,
                                        size: 14,
                                        color: msg.status == MessageStatus.read ? AppColors.cyan : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),

                                // Reaction Badges
                                if (msg.reactions.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: msg.reactions.entries.map((entry) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.white24 : AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${entry.key} ${entry.value}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: _quickChips.map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(chip.tr(), style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        onPressed: () => _sendMessage(text: chip.tr()),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Replying Preview Banner
              if (state.replyingMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    border: Border(
                      top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to ${state.replyingMessage!.senderName}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            Text(
                              state.replyingMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          context.read<ChatBloc>().add(const SetReplyingMessage(null));
                        },
                      ),
                    ],
                  ),
                ),

              // Telegram Input Bar (Mic / Hold-to-record / Attachment sheet)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: state.isRecordingVoice
                      // Telegram Dictaphone Voice Recording Active Bar
                      ? Row(
                          children: [
                            // Pulsing Red Recording Indicator
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.rose,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.rose,
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Recording Timer
                            Text(
                              '${state.recordingDurationSeconds ~/ 60}:${(state.recordingDurationSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppColors.rose,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Animated Telegram Audio Waveform Equalizer
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    (state.recordingWaveform.length).clamp(8, 20),
                                    (index) {
                                      final sample = index < state.recordingWaveform.length
                                          ? state.recordingWaveform[index]
                                          : 0.3;
                                      final h = (sample * 24.0).clamp(4.0, 26.0);
                                      return Container(
                                        width: 3,
                                        height: h,
                                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Discard / Delete Voice Note Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose, size: 24),
                              tooltip: 'Bekor qilish',
                              onPressed: () {
                                context.read<ChatBloc>().add(const StopVoiceRecording(cancel: true));
                              },
                            ),

                            // Send Voice Note Button (Telegram Style Blue Circle)
                            GestureDetector(
                              onTap: () {
                                final dur = state.recordingDurationSeconds > 0 ? state.recordingDurationSeconds : 3;
                                final waveform = state.recordingWaveform.isNotEmpty
                                    ? state.recordingWaveform
                                    : const [0.3, 0.6, 0.9, 0.4, 0.8, 0.5, 0.2, 0.7, 0.9, 0.6, 0.4];

                                context.read<ChatBloc>().add(const StopVoiceRecording(cancel: false));
                                _sendMessage(
                                  type: MessageType.voiceNote,
                                  voicePayload: VoiceNotePayload(
                                    durationSeconds: dur,
                                    waveformSamples: waveform,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        )
                      // Normal Input Field Bar
                      : Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file_rounded, size: 20),
                              tooltip: 'chat.attachDoc'.tr(),
                              onPressed: () => _openAttachmentSheet(context),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'chat.typeMessage'.tr(),
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_hasText)
                              IconButton(
                                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                                onPressed: () => _sendMessage(),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  context.read<ChatBloc>().add(StartVoiceRecording());
                                },
                                onLongPress: () {
                                  context.read<ChatBloc>().add(StartVoiceRecording());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
