import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import '../../domain/yolo_service.dart';
import 'yolo_bounding_box_painter.dart';

/// Modal Pratinjau Interaktif dengan Zoom In/Out (InteractiveViewer), Rotasi 90°,
/// serta overlay Bounding Box YOLOv8 hasil inferensi on-device
class InteractivePhotoPreviewModal extends StatefulWidget {
  const InteractivePhotoPreviewModal({
    super.key,
    required this.imageFile,
    required this.detections,
    this.title = 'Pratinjau Hasil Pindai AI',
  });

  final File imageFile;
  final List<YoloDetection> detections;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required File imageFile,
    required List<YoloDetection> detections,
    String title = 'Pratinjau Hasil Pindai AI',
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => InteractivePhotoPreviewModal(
        imageFile: imageFile,
        detections: detections,
        title: title,
      ),
    );
  }

  @override
  State<InteractivePhotoPreviewModal> createState() => _InteractivePhotoPreviewModalState();
}

class _InteractivePhotoPreviewModalState extends State<InteractivePhotoPreviewModal> {
  final TransformationController _transformController = TransformationController();
  int _rotationQuarterTurns = 0;
  bool _showBoxes = true;
  YoloDetection? _selectedDetection;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _rotate90() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
      _rotationQuarterTurns = 0;
      _selectedDetection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              '${widget.detections.length} Kompartemen Terdeteksi (On-Device YOLOv8)',
              style: const TextStyle(fontSize: 11, color: AppColors.emerald),
            ),
          ],
        ),
        actions: [
          // Toggle Bounding Boxes
          IconButton(
            tooltip: _showBoxes ? 'Sembunyikan Kotak' : 'Tampilkan Kotak',
            icon: Icon(
              _showBoxes ? LucideIcons.eye : LucideIcons.eyeOff,
              color: _showBoxes ? AppColors.emerald : Colors.white70,
            ),
            onPressed: () => setState(() => _showBoxes = !_showBoxes),
          ),
          // Rotate 90°
          IconButton(
            tooltip: 'Putar 90°',
            icon: const Icon(LucideIcons.rotateCw, color: Colors.white),
            onPressed: _rotate90,
          ),
          // Reset Zoom
          IconButton(
            tooltip: 'Reset Zoom',
            icon: const Icon(LucideIcons.maximize2, color: Colors.white),
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Viewport with Pinch to Zoom
          Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: RotatedBox(
                quarterTurns: _rotationQuarterTurns,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                    ),
                    if (_showBoxes && widget.detections.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: YoloBoundingBoxPainter(
                            detections: widget.detections,
                            selectedDetection: _selectedDetection,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar: Detection Pill Chips
          if (widget.detections.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.detections.map((det) {
                        final isSelected = _selectedDetection?.classId == det.classId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            selectedColor: AppColors.emerald.withValues(alpha: 0.35),
                            side: BorderSide(
                              color: isSelected ? AppColors.emerald : Colors.white24,
                            ),
                            label: Text(
                              '${det.label.toUpperCase()} (${(det.confidence * 100).toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.emerald : Colors.white,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedDetection = isSelected ? null : det;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
