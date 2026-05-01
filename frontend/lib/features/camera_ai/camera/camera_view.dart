import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

class CameraState {
  final CameraController? controller;
  final bool isReady;
  final String? error;

  CameraState({
    this.controller,
    this.isReady = false,
    this.error,
  });
}

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(CameraState());
}

class CameraView extends ConsumerWidget {
  const CameraView({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    
    if (!cameraState.isReady) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (cameraState.error != null) {
      return Center(child: Text('Camera Error: ${cameraState.error}'));
    }
    
    return CameraPreview(cameraState.controller!);
  }
}
