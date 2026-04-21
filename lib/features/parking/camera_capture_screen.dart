import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    required this.isCantonese,
  });

  final bool isCantonese;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = widget.isCantonese
              ? '裝置搵唔到相機。'
              : 'No camera was found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameras = cameras;
        _controller = controller;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            widget.isCantonese ? '相機暫時開唔到。' : 'The camera could not be opened.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isCantonese
                ? '影相失敗，請再試一次。'
                : 'Photo capture failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isCantonese ? '拍攝現場照片' : 'Take Parking Photo'),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _initCamera,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                              widget.isCantonese ? '重新開啟相機' : 'Retry camera'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: controller == null
                          ? const SizedBox.shrink()
                          : Center(
                              child: AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(controller),
                              ),
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isCantonese
                                  ? (_cameras.any((item) =>
                                          item.lensDirection ==
                                          CameraLensDirection.back)
                                      ? '已用後置鏡頭'
                                      : '已開啟相機')
                                  : (_cameras.any((item) =>
                                          item.lensDirection ==
                                          CameraLensDirection.back)
                                      ? 'Rear camera ready'
                                      : 'Camera ready'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _isCapturing ? null : _capture,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D52),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                              ),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label:
                                  Text(widget.isCantonese ? '拍照' : 'Capture'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
