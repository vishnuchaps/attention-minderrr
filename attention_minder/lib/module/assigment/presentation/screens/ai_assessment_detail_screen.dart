import 'package:camera/camera.dart';
import 'package:attention_minder/Config/widgets/user_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AiAssessmentDetailScreen extends StatefulWidget {
  /// The URL (or local path) of the PDF file received from the backend.
  final String pdfFile;

  const AiAssessmentDetailScreen({super.key, required this.pdfFile});

  @override
  State<AiAssessmentDetailScreen> createState() =>
      _AiAssessmentDetailScreenState();
}

class _AiAssessmentDetailScreenState extends State<AiAssessmentDetailScreen> {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraVisible = true; // user can toggle the PiP

  // ── PDF ─────────────────────────────────────────────────────────────────
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _pdfLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _pageLabel =>
      _totalPages > 0 ? '$_currentPage / $_totalPages' : '—';

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // ── AppBar ────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.black,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            if (_totalPages > 0)
              Text(
                'Page $_pageLabel',
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          // Camera toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _isCameraVisible ? 'Hide camera' : 'Show camera',
              onPressed: () =>
                  setState(() => _isCameraVisible = !_isCameraVisible),
              icon: Icon(
                _isCameraVisible
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                color: _isCameraVisible
                    ? const Color(0xFF0F78FE)
                    : const Color(0xFF9E9E9E),
                size: 22,
              ),
            ),
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const UserProfileAvatar(size: 36),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F78FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Body ──────────────────────────────────────────────────────────
      body: Stack(
        children: [
          // ── PDF viewer fills the screen ──────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 88), // room for bottom bar
            child: _buildPdfViewer(),
          ),

          // ── Camera PiP ───────────────────────────────────────────────
          if (_isCameraInitialized && _isCameraVisible) _buildCameraPiP(),

          // ── Bottom action bar ────────────────────────────────────────
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // ── PDF Viewer ───────────────────────────────────────────────────────────

  Widget _buildPdfViewer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // PDF view
          SfPdfViewer.network(
            widget.pdfFile,
            controller: _pdfController,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            scrollDirection: PdfScrollDirection.vertical,
            enableDoubleTapZooming: true,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _pdfLoading = false;
              });
            },
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
            },
            onDocumentLoadFailed: (details) {
              setState(() => _pdfLoading = false);
              _showError('Failed to load assessment: ${details.description}');
            },
          ),

          // Loading overlay
          if (_pdfLoading)
            Container(
              color: const Color(0xFF141414),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0F78FE)),
                    SizedBox(height: 16),
                    Text(
                      'Loading assessment…',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                        fontFamily: 'Nunito Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Camera picture-in-picture ────────────────────────────────────────────

  Widget _buildCameraPiP() {
    return Positioned(
      top: 16,
      right: 24,
      child: Container(
        width: 100,
        height: 134,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0F78FE), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F78FE).withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Camera preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CameraPreview(_cameraController!),
            ),

            // Corner brackets (scanning indicator)
            ..._cornerBrackets(),

            // "LIVE" badge
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F78FE).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 7,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cornerBrackets() {
    const color = Colors.red;
    const size = 14.0;
    const thickness = 2.0;

    Widget bracket({
      required AlignmentGeometry alignment,
      required Border border,
    }) => Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(decoration: BoxDecoration(border: border)),
          ),
        ),
      ),
    );

    return [
      bracket(
        alignment: Alignment.topLeft,
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      bracket(
        alignment: Alignment.topRight,
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
      bracket(
        alignment: Alignment.bottomLeft,
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      bracket(
        alignment: Alignment.bottomRight,
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
    ];
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // PDF navigation controls
          _navButton(
            icon: Icons.first_page_rounded,
            tooltip: 'First page',
            onTap: () => _pdfController.jumpToPage(1),
          ),
          const SizedBox(width: 8),
          _navButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous page',
            onTap: () => _pdfController.previousPage(),
          ),
          const SizedBox(width: 8),
          _navButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next page',
            onTap: () => _pdfController.nextPage(),
          ),
          const SizedBox(width: 8),
          _navButton(
            icon: Icons.last_page_rounded,
            tooltip: 'Last page',
            onTap: () =>
                _totalPages > 0 ? _pdfController.jumpToPage(_totalPages) : null,
          ),

          const Spacer(),

          // Result button
          GestureDetector(
            onTap: () {
              // TODO: navigate to result screen
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F78FE),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F78FE).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Result',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.north_east_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
        ),
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF5350),
      ),
    );
  }
}
