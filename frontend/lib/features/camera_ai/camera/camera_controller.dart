import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraControllerNotifier extends StateNotifier<CameraState> {
  CameraController? _controller;
  
  CameraControllerNotifier() : super(CameraState.initial());
  
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // For ML processing
      );
      
      await _controller!.initialize();
      state = CameraState.ready(_controller!);
    } catch (e) {
      state = CameraState.error(e.toString());
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// State model
class CameraState {
  final CameraController? controller;
  final bool isReady;
  final String? error;
  
  CameraState({this.controller, this.isReady = false, this.error});
  
  factory CameraState.initial() => CameraState();
  factory CameraState.ready(CameraController controller) => 
      CameraState(controller: controller, isReady: true);
  factory CameraState.error(String error) => 
      CameraState(error: error);
}

// Provider
final cameraProvider = StateNotifierProvider<CameraControllerNotifier, CameraState>(
  (ref) => CameraControllerNotifier(),
);
