import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/colors.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() { _errorMessage = 'No webcams found on this device.'; _isInitializing = false; });
        return;
      }
      // Uses the default laptop webcam
      _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      setState(() { _isInitializing = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Camera blocked. Please allow browser permissions.'; _isInitializing = false; });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      // 1. Snap the photo
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      
      if (!mounted) return;
      
      // 2. Pass the photo to your provider
      final filename = 'Webcam_Capture_${DateTime.now().millisecondsSinceEpoch}.png';
      context.read<AppProvider>().uploadImageBytes(bytes, filename);
      
      // 3. Close the camera and go back to the workspace
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Live Clinical Capture', style: TextStyle(fontSize: 16)),
      ),
      body: Center(
        child: _isInitializing
            ? const CircularProgressIndicator(color: AppColors.primaryButton)
            : _errorMessage.isNotEmpty
                ? Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16))
                : Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.primaryButton, width: 2)),
                    child: CameraPreview(_controller!),
                  ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isInitializing || _errorMessage.isNotEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primaryButton,
              onPressed: _takePicture,
              child: const Icon(Icons.camera, color: Colors.black, size: 30),
            ),
    );
  }
}