import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:intl/intl.dart'; 

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'camera_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  
  void _showImageSourceActionSheet(BuildContext context, AppProvider provider) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(padding: EdgeInsets.all(20.0), child: Text('Select Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              if (isMobile) 
                ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.primaryButton), title: const Text('Take a Photo (Camera)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)), onTap: () { Navigator.of(context).pop(); Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())); }),
              ListTile(leading: const Icon(Icons.photo_library, color: AppColors.primaryButton), title: const Text('Choose from Gallery / Files', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)), onTap: () { Navigator.of(context).pop(); provider.pickAndUploadImage(source: ImageSource.gallery); }),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMarkdownText(String text) {
    final List<TextSpan> spans = [];
    final RegExp combinedExp = RegExp(r'\*\*(.*?)\*\*|\[([^\]]+)\]\((https?:\/\/[^\s\)]+)\)|(https?:\/\/[^\s\)]+)');
    int lastMatchEnd = 0;
    
    for (var match in combinedExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: const TextStyle(color: AppColors.textPrimary)));
      }
      
      if (match.group(1) != null) { 
        final String diagnosisTerm = match.group(1)!;
        spans.add(
          TextSpan(
            text: diagnosisTerm, 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(diagnosisTerm + " medical clinical diagnosis")}')),
          )
        );
      } else if (match.group(2) != null && match.group(3) != null) { 
        spans.add(TextSpan(text: match.group(2)!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold), recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(match.group(3)!))));
      } else if (match.group(4) != null) { 
        spans.add(TextSpan(text: match.group(4)!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(match.group(4)!))));
      }
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: const TextStyle(color: AppColors.textPrimary)));
    }
    
    return RichText(text: TextSpan(children: spans, style: const TextStyle(fontSize: 15, height: 1.8)));
  }

  Future<void> _generatePdf(BuildContext context, ImageRecord image, UserModel? user, AppProvider provider) async {
    if (image.imageBytes == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)));
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(image.imageBytes!);
    pdf.addPage(
      pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40), build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('CliniView Workspace', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Text('Official Clinical Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700))]), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text('Date: ${image.dateUploaded}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)), pw.Text('Reviewer: ${user?.firstName ?? ''} ${user?.lastName ?? ''}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))])])), pw.SizedBox(height: 20),
            pw.Center(child: pw.Container(height: 250, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)), child: pw.Image(pdfImage, fit: pw.BoxFit.contain))), pw.SizedBox(height: 20),
            pw.Text('Visual Summary & Diagnoses', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Divider(color: PdfColors.grey300), pw.SizedBox(height: 8),
            if (image.description.isEmpty) pw.Text('No description available.', style: const pw.TextStyle(fontSize: 11)) else ...image.description.split('\n').map((paragraph) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(paragraph.replaceAll('*', ''), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)))), pw.SizedBox(height: 30),
            pw.Text('Clinical Annotations', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Divider(color: PdfColors.grey300), pw.SizedBox(height: 8),
            if (image.markers.isEmpty) pw.Text('No markers attached.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)) else pw.Table.fromTextArray(context: context, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800), cellStyle: const pw.TextStyle(fontSize: 10), cellAlignment: pw.Alignment.topLeft, cellPadding: const pw.EdgeInsets.all(8), data: <List<String>>[['Marker', 'Coordinates', 'Notes & Comments'], ...image.markers.asMap().entries.map((entry) { final index = entry.key + 1; final marker = entry.value; final coords = 'X: ${(marker.x * 100).toStringAsFixed(1)}%\nY: ${(marker.y * 100).toStringAsFixed(1)}%'; String comments = ''; for(int i = 0; i < marker.comments.length; i++) { comments += '• ${marker.comments[i]} (${marker.commentTimestamps[i]})\n'; } if (comments.isEmpty) comments = 'No notes attached.'; return ['Point ${index.toString().padLeft(2, '0')}', coords, comments.trim()]; }), ]),
          ];
      }),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'CliniView_Report_${image.filename}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeImage = provider.activeImage;
    final isLoading = provider.isLoading;
    final user = provider.currentUser;
    final bool isMobile = MediaQuery.of(context).size.width < 600; 
    
    final bool isCompareMode = activeImage?.filename == "Comparison Report" && provider.comparisonRecords.length == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppConstants.cardRadius), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16, runSpacing: 16,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompareMode) const Icon(Icons.circle, color: AppColors.accentYellow, size: 12),
                          if (isCompareMode) const SizedBox(width: 8),
                          Text(isCompareMode ? 'COMPARISON WORKSPACE' : 'IMAGE WORKSPACE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary)),
                        ],
                      ),
                      if (activeImage != null && !isCompareMode)
                        Wrap(
                          spacing: 12, runSpacing: 12,
                          children: [
                            // FIX: Shortened text and gave them plenty of safe pixel space!
                            CustomButton(text: 'Download', icon: Icons.picture_as_pdf_outlined, width: 150, isOutlined: true, onPressed: () => _generatePdf(context, activeImage, user, provider)),
                            CustomButton(text: 'Upload New', icon: Icons.camera_alt_outlined, width: 160, isOutlined: true, onPressed: () => _showImageSourceActionSheet(context, provider))
                          ]
                        )
                      else if (isCompareMode)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(12)), child: const Text("2 SELECTED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)))
                    ],
                  ),
                  
                  if (isCompareMode) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: [
                        CustomButton(text: "Back to review", width: 170, onPressed: () => provider.clearWorkspace()),
                        CustomButton(text: "Clear selection", width: 170, isOutlined: true, onPressed: () => provider.clearWorkspace()),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity, constraints: const BoxConstraints(minHeight: 300, maxHeight: 600),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight, style: activeImage == null ? BorderStyle.solid : BorderStyle.none)),
                    child: isLoading 
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryButton)) 
                      : activeImage == null 
                        ? _buildEmptyUploadState(context, provider) 
                        : isCompareMode 
                          ? _buildComparisonImages(provider, isMobile)
                          : _buildInteractiveImage(context, activeImage, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            if (activeImage != null && !isLoading)
              Container(
                width: double.infinity, padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppConstants.cardRadius), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCompareMode)
                      Container(width: double.infinity, constraints: const BoxConstraints(maxWidth: 400), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLight)), child: Row(children: [Expanded(child: _buildTab(provider, 0, 'Description')), Expanded(child: _buildTab(provider, 1, 'Annotations'))])),
                    if (isCompareMode)
                      const Row(children: [Icon(Icons.circle, color: AppColors.accentYellow, size: 12), SizedBox(width: 8), Text('CLINICAL REVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary))]),
                    const SizedBox(height: 32),
                    provider.activeWorkspaceTab == 0 || isCompareMode ? _buildDescriptionContent(activeImage) : _buildAnnotationContent(provider, activeImage),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // FIX: Make the side-by-side images stack vertically on mobile screens
  Widget _buildComparisonImages(AppProvider provider, bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildCompareCard(provider.comparisonRecords[0], provider.comparisonDates[0], true),
            const SizedBox(height: 16),
            _buildCompareCard(provider.comparisonRecords[1], provider.comparisonDates[1], true),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(child: _buildCompareCard(provider.comparisonRecords[0], provider.comparisonDates[0], false)),
        const SizedBox(width: 16),
        Expanded(child: _buildCompareCard(provider.comparisonRecords[1], provider.comparisonDates[1], false)),
      ],
    );
  }

  Widget _buildCompareCard(ImageRecord record, DateTime date, bool isMobile) {
    return Container(
      height: isMobile ? 300 : null,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: record.imageBytes != null ? Image.memory(record.imageBytes!, fit: BoxFit.cover, width: double.infinity) : const Center(child: Icon(Icons.image_not_supported, color: AppColors.textSecondary, size: 40)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16), width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
            child: Column(
              children: [
                Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(DateFormat('hh:mm a').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyUploadState(BuildContext context, AppProvider provider) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, size: 50, color: AppColors.textSecondary)), const SizedBox(height: 24), const Text('Ready for Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Select a clinical image to begin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)), const SizedBox(height: 32), CustomButton(text: 'Capture or Browse', width: 220, onPressed: () => _showImageSourceActionSheet(context, provider))]);
  }

  Widget _buildInteractiveImage(BuildContext context, ImageRecord image, AppProvider provider) {
    if (image.imageBytes == null) { return Container(width: double.infinity, color: AppColors.background, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cloud_done_outlined, size: 64, color: AppColors.primaryButton), const SizedBox(height: 16), Text(image.filename, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: 8), const Text("Record loaded from server.", style: TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 4), const Text("(Image file not stored in database)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])); }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(onTapUp: (details) { final double x = details.localPosition.dx / constraints.maxWidth; final double y = details.localPosition.dy / constraints.maxHeight; provider.addMarker(x, y); }, child: Image.memory(image.imageBytes!, fit: BoxFit.contain)),
              ...image.markers.asMap().entries.map((entry) {
                final index = entry.key; final marker = entry.value; final isSelected = provider.selectedMarker?.id == marker.id;
                return Positioned(left: marker.x * constraints.maxWidth - 16, top: marker.y * constraints.maxHeight - 16, child: GestureDetector(onTap: () => provider.selectMarker(marker), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: isSelected ? Colors.yellow : Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: isSelected ? 3 : 1), boxShadow: isSelected ? [const BoxShadow(color: Colors.yellow, blurRadius: 8)] : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)]), child: Center(child: Text('${index + 1}', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14))))));
              }),
              Positioned(bottom: 16, right: 16, child: InkWell(onTap: () => _showImageViewerDialog(context, image), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]), child: const Icon(Icons.crop_free, color: Colors.white, size: 24)))),
            ],
          );
        },
      ),
    );
  }

  void _showImageViewerDialog(BuildContext context, ImageRecord image) {
    if (image.imageBytes == null) return; 
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.all(isMobile ? 16 : 40), child: Container(width: 1100, height: 800, decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12))]), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _ImageViewerOverlay(image: image)))));
  }

  Widget _buildTab(AppProvider provider, int index, String title) {
    final isSelected = provider.activeWorkspaceTab == index;
    return GestureDetector(onTap: () => provider.setWorkspaceTab(index), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? AppColors.primaryButton : Colors.transparent, borderRadius: BorderRadius.circular(24)), alignment: Alignment.center, child: Text(title, style: TextStyle(color: isSelected ? AppColors.accentYellow : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14))));
  }

  Widget _buildDescriptionContent(ImageRecord image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(image.filename == "Comparison Report" ? 'Description' : 'Visual Summary', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        image.description.isNotEmpty 
          ? _buildMarkdownText(image.description)
          : const Text('Awaiting API integration results...', style: TextStyle(fontSize: 15, height: 1.8, color: AppColors.textSecondary)),
      ]
    );
  }

  Widget _buildAnnotationContent(AppProvider provider, ImageRecord activeImage) {
    final marker = provider.selectedMarker;
    if (marker == null) return const Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Center(child: Text('Click anywhere on the image above to drop a marker.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))));
    final markerIndex = activeImage.markers.indexOf(marker) + 1;
    final indexString = markerIndex.toString().padLeft(2, '0');
    final controller = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECTED ANNOTATION - POINT $indexString', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)), child: Text('Marker $markerIndex • ${marker.comments.length} entries', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(height: 24),
        if (marker.comments.isNotEmpty) ...[
          ...marker.comments.asMap().entries.map((entry) {
            final commentIndex = entry.key; final commentText = entry.value; final timestamp = marker.commentTimestamps[commentIndex];
            return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.focusBorder.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(commentText, style: const TextStyle(fontSize: 15, height: 1.4))), IconButton(onPressed: () => provider.removeComment(marker, commentIndex), icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), tooltip: 'Remove Entry', visualDensity: VisualDensity.compact)]), const SizedBox(height: 8), Text(timestamp, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.0))]));
          }),
          const SizedBox(height: 24),
        ],
        const Text('Add comment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        CustomTextField(controller: controller, hint: 'Add a comment for the selected image marker...', maxLines: 4),
        const SizedBox(height: 16),
        CustomButton(text: 'Add comment', width: 160, onPressed: () { provider.addCommentToMarker(controller.text); FocusManager.instance.primaryFocus?.unfocus(); })
      ],
    );
  }
}

class _ImageViewerOverlay extends StatefulWidget {
  final ImageRecord image;
  const _ImageViewerOverlay({required this.image});
  @override State<_ImageViewerOverlay> createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<_ImageViewerOverlay> {
  final PhotoViewController _controller = PhotoViewController();
  final GlobalKey _boundaryKey = GlobalKey();
  int _zoomPercentage = 100;
  bool _isSaving = false;
  @override void dispose() { _controller.dispose(); super.dispose(); }
  void _zoomIn() { setState(() { if (_zoomPercentage < 300) _zoomPercentage += 10; }); _controller.scale = (_controller.scale ?? 1.0) * 1.1; }
  void _zoomOut() { setState(() { if (_zoomPercentage > 10) _zoomPercentage -= 10; }); _controller.scale = (_controller.scale ?? 1.0) * 0.9; }
  void _fit() { setState(() => _zoomPercentage = 100); _controller.scale = null; }
  Future<void> _saveAndCrop(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (context.mounted) { context.read<AppProvider>().saveCroppedImage(widget.image, byteData!.buffer.asUint8List()); Navigator.of(context).pop(); }
    } catch (e) { setState(() => _isSaving = false); }
  }
  @override Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600; 
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 16), color: const Color(0xFF2C2C2C),
          child: isMobile 
            ? Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.image.filename, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop())]), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [_ViewerButton(text: '-', onTap: _zoomOut), const SizedBox(width: 8), _ViewerButton(text: '$_zoomPercentage%', onTap: _fit, width: 60), const SizedBox(width: 8), _ViewerButton(text: '+', onTap: _zoomIn)]), _ViewerButton(text: _isSaving ? '...' : 'SAVE', onTap: _isSaving ? () {} : () => _saveAndCrop(context), isPrimary: true, width: 80)])])
            : Row(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CROP / ZOOM VIEWER', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)), const SizedBox(height: 4), Text(widget.image.filename, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))]), const Spacer(), _ViewerButton(text: '-', onTap: _zoomOut), const SizedBox(width: 8), _ViewerButton(text: '$_zoomPercentage%', onTap: _fit, width: 60), const SizedBox(width: 8), _ViewerButton(text: '+', onTap: _zoomIn), const SizedBox(width: 8), _ViewerButton(text: 'FIT', onTap: _fit, width: 60), const SizedBox(width: 24), _ViewerButton(text: 'CANCEL', onTap: () => Navigator.of(context).pop(), width: 80), const SizedBox(width: 8), _ViewerButton(text: _isSaving ? 'SAVING...' : 'SAVE & CROP', onTap: _isSaving ? () {} : () => _saveAndCrop(context), isPrimary: true, width: 120)]),
        ),
        Expanded(child: ClipRect(child: RepaintBoundary(key: _boundaryKey, child: PhotoView(imageProvider: MemoryImage(widget.image.imageBytes!), controller: _controller, minScale: PhotoViewComputedScale.contained * 0.1, maxScale: PhotoViewComputedScale.covered * 4, initialScale: PhotoViewComputedScale.contained, backgroundDecoration: const BoxDecoration(color: Colors.black))))),
      ],
    );
  }
}

class _ViewerButton extends StatelessWidget {
  final String text; final VoidCallback onTap; final double width; final bool isPrimary;
  const _ViewerButton({required this.text, required this.onTap, this.width = 40, this.isPrimary = false});
  @override Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(width: width, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: isPrimary ? AppColors.focusBorder : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPrimary ? AppColors.focusBorder : Colors.grey.shade700)), child: Text(text, style: TextStyle(color: isPrimary ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.bold))));
  }
}

// FIX: Added Scrolling and Wrap constraints to make the popup totally safe on Mobile!
class ComparisonDateDialog extends StatefulWidget {
  final List<ImageRecord> selectedImages;
  const ComparisonDateDialog({super.key, required this.selectedImages});
  @override State<ComparisonDateDialog> createState() => _ComparisonDateDialogState();
}

class _ComparisonDateDialogState extends State<ComparisonDateDialog> {
  DateTime? date1; DateTime? date2;

  Future<void> _pickDateTime(int index) async {
    DateTime? d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d != null && mounted) {
      TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (t != null && mounted) {
        setState(() {
          DateTime combined = DateTime(d.year, d.month, d.day, t.hour, t.minute);
          if (index == 0) date1 = combined; else date2 = combined;
        });
      }
    }
  }

  Widget _buildPickerCard(int index, ImageRecord image, DateTime? selectedDate, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 250, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: image.imageBytes != null ? Image.memory(image.imageBytes!, width: 48, height: 48, fit: BoxFit.cover) : Container(width: 48, height: 48, color: AppColors.background, child: const Icon(Icons.image, color: Colors.grey))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('IMAGE ${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)), Text(image.filename, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)])),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Captured date and time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickDateTime(index),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedDate != null ? DateFormat('MM-dd-yyyy HH:mm').format(selectedDate) : 'Select date & time', style: TextStyle(color: selectedDate != null ? Colors.black : Colors.grey.shade600, fontSize: 13)), const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black)])),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedImages.length != 2) return const SizedBox.shrink();
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12, runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text("COMPARISON SETUP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)), 
                      const SizedBox(height: 4), 
                      Text("Pick the captured date", style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold))
                    ]
                  ), 
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)), child: const Text("2 SELECTED", style: TextStyle(color: Color(0xFF8D6E63), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)))
                ]
              ),
              const SizedBox(height: 24),
              
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16, runSpacing: 16,
                children: [
                  _buildPickerCard(0, widget.selectedImages[0], date1, isMobile), 
                  _buildPickerCard(1, widget.selectedImages[1], date2, isMobile)
                ]
              ),
              
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12, runSpacing: 12,
                children: [
                  TextButton(onPressed: () { context.read<AppProvider>().clearWorkspace(); Navigator.pop(context); }, child: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
                  CustomButton(text: "Clear", width: 100, isOutlined: true, onPressed: () { context.read<AppProvider>().clearWorkspace(); Navigator.pop(context); }),
                  
                  CustomButton(text: "Compare", width: 150, onPressed: (date1 != null && date2 != null) ? () { 
                    Navigator.pop(context); 
                    context.read<AppProvider>().executeComparisonWithDates(
                      widget.selectedImages[0].id, date1!, 
                      widget.selectedImages[1].id, date2!
                    ); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Merging images and running analysis...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.green, duration: Duration(seconds: 4),
                      )
                    );
                  } : () {}), 
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}