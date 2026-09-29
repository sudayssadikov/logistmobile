import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/call_model.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';

class IncomingCallOverlay extends StatefulWidget {
  final CallSessionModel session;

  const IncomingCallOverlay({super.key, required this.session});

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.session.type == CallType.video;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Incoming Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                      color: AppColors.primaryLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'Incoming HD Video Call...' : 'Incoming HD Audio Call...',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Center Caller Avatar with Animated Pulse
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(12 + (_animController.value * 12)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15 * (1 - _animController.value)),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 54),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.session.callerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.session.codec,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),

              // Bottom Accept / Decline Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button
                  GestureDetector(
                    onTap: () {
                      context.read<CallBloc>().add(DeclineCallRequested(widget.session.id));
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 8),
                        const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),

                  // Accept Button
                  GestureDetector(
                    onTap: () {
                      context.read<CallBloc>().add(AnswerCallRequested(widget.session.id));
                      context.push('/calls/active');
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accept', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
