import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/call_model.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state.activeSession == null || state.activeSession!.status == CallStatus.ended) {
          context.pop();
        }
      },
      builder: (context, state) {
        final session = state.activeSession ??
            CallSessionModel(
              id: 'CALL-001',
              callerId: 'USR-ME',
              callerName: 'You',
              callerRole: UserRole.shipper,
              receiverId: 'USR-DRIVER-01',
              receiverName: 'Rustam Karimov (Driver)',
              receiverRole: UserRole.driver,
              type: CallType.audio,
              status: CallStatus.active,
              startedAt: DateTime.now(),
              durationSeconds: 15,
            );

        final isVideo = session.type == CallType.video && session.isVideoEnabled;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Deep Slate 900
          body: Stack(
            children: [
              // Background / Video Stream Simulation
              if (isVideo)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF1E293B),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_rounded, size: 64, color: Colors.white24),
                              const SizedBox(height: 12),
                              Text(
                                'Remote Stream: ${session.receiverName}',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '1080p 60fps • VP8 Hardware Encoded',
                                style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        // Local PIP Video Preview (Draggable feel)
                        Positioned(
                          top: 50,
                          right: 16,
                          child: Container(
                            width: 100,
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30, width: 1.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 10),
                              ],
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.face_rounded, color: Colors.white70, size: 28),
                                  SizedBox(height: 4),
                                  Text('Self View', style: TextStyle(color: Colors.white60, fontSize: 9)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // HD Audio Ambient Glow Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 0.8,
                        colors: [
                          Color(0xFF1E3A8A), // Indigo Deep
                          Color(0xFF0F172A), // Slate 900
                        ],
                      ),
                    ),
                  ),
                ),

              // Top Status Header (Timer & Encryption Badge)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: AppColors.emerald, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              session.networkQuality,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session.status == CallStatus.active ? session.formattedDuration : 'Connecting...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center Audio Mode Avatar
              if (!isVideo)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            padding: EdgeInsets.all(16 + (_waveController.value * 14)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15 * (1 - _waveController.value)),
                            ),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 58),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        session.receiverName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.codec,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),

              // Bottom Control Dock
              Positioned(
                bottom: 36,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Mute Button
                      _CallControlButton(
                        icon: session.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: session.isMicMuted,
                        onTap: () {
                          context.read<CallBloc>().add(
                                ToggleMuteRequested(
                                  callId: session.id,
                                  isMuted: !session.isMicMuted,
                                ),
                              );
                        },
                      ),

                      // Speakerphone Button
                      _CallControlButton(
                        icon: session.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        isActive: session.isSpeakerOn,
                        onTap: () {
                          context.read<CallBloc>().add(
                                ToggleSpeakerRequested(
                                  callId: session.id,
                                  isSpeakerOn: !session.isSpeakerOn,
                                ),
                              );
                        },
                      ),

                      // Video Toggle Button
                      _CallControlButton(
                        icon: session.isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        isActive: session.isVideoEnabled,
                        onTap: () {
                          context.read<CallBloc>().add(
                                ToggleVideoRequested(
                                  callId: session.id,
                                  isVideoEnabled: !session.isVideoEnabled,
                                ),
                              );
                        },
                      ),

                      // Flip Camera (If Video active)
                      if (session.type == CallType.video)
                        _CallControlButton(
                          icon: Icons.flip_camera_ios_rounded,
                          isActive: false,
                          onTap: () {
                            context.read<CallBloc>().add(
                                  SwitchCameraRequested(
                                    callId: session.id,
                                    isFrontCamera: !session.isFrontCamera,
                                  ),
                                );
                          },
                        ),

                      // End Call Button (Red)
                      GestureDetector(
                        onTap: () {
                          context.read<CallBloc>().add(EndCallRequested(session.id));
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF0F172A) : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
