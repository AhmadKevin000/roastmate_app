import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen UI untuk "Scan Kamera" pada aplikasi Roastmate.
/// Dibuat sesuai arsitektur MVVM + Feature-First (Statis / UI Dummy).
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // State interaktif sederhana untuk keperluan UI dummy
  String _selectedZoom = '1x';
  bool _isFlashOn = false;
  bool _isLightOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF231A16),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Area Pemindaian Kamera (Viewfinder + Overlay)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Placeholder Latar Belakang Tampilan Kamera
                      Positioned.fill(
                        child: _CameraPreviewPlaceholder(
                          isLightOn: _isLightOn,
                        ),
                      ),

                      // 2. Baris Tombol Atas (Close, Batch Pill, Light)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tombol Close (X)
                            _IconButtonCircle(
                              icon: Icons.close,
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                            ),

                            // Badge "Scan Batch Kopi"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C231E).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scan Batch Kopi',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Lightbulb / Lampu Pencerah
                            _IconButtonCircle(
                              icon: _isLightOn
                                  ? Icons.lightbulb
                                  : Icons.lightbulb_outline,
                              iconColor: _isLightOn
                                  ? const Color(0xFFFDE047)
                                  : Colors.white,
                              onTap: () {
                                setState(() {
                                  _isLightOn = !_isLightOn;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // 3. Petunjuk & Indikator Pencahayaan (Di Atas Frame Kotak)
                      Positioned(
                        top: 72,
                        child: Column(
                          children: [
                            // Teks Instruksi: "Arahkan kamera ke biji kopi..."
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF231B17).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.crop_free_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Arahkan kamera ke biji kopi yang terlihat',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Badge Indikator "Pencahayaan Baik"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534).withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF86EFAC),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pencahayaan Baik',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF86EFAC),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Frame Area Pemindaian (Cutout Siku Putih & Target Circle)
                      Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          margin: const EdgeInsets.only(top: 10),
                          child: Stack(
                            children: [
                              // Siku-siku Putih di 4 Sudut Viewfinder
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ViewfinderCornerPainter(),
                                ),
                              ),

                              // Dotted Target Circle di Tengah
                              Center(
                                child: CustomPaint(
                                  size: const Size(60, 60),
                                  painter: TargetReticlePainter(),
                                ),
                              ),

                              // Highlight Spot Transparan (Detail visual dari gambar)
                              Positioned(
                                top: 75,
                                left: 75,
                                child: Container(
                                  width: 44,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAB308).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEAB308),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 5. Teks Instruksi Bawah Viewfinder: "Tidak perlu menata..."
                      Positioned(
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF231B17).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.grain,
                                color: Color(0xFFD4C8BE),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tidak perlu menata satu per satu biji',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Panel Kontrol Bawah (Bottom Controls Panel)
                _BottomControlPanel(
                  selectedZoom: _selectedZoom,
                  onZoomChanged: (zoom) {
                    setState(() {
                      _selectedZoom = zoom;
                    });
                  },
                  isFlashOn: _isFlashOn,
                  onFlashToggled: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// App Bar Transparan / Bergaya Kustom dengan Tombol Back, Judul & Avatar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F0EB),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF3D2A20),
          size: 24,
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Badge Cokelat Bundar Dengan Ikon Biji Kopi
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF5A382C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grain_rounded,
              color: Color(0xFFF5F0EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Scan Biji Kopi',
            style: GoogleFonts.inter(
              color: const Color(0xFF3D2A20),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4A2E23),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFFF5F0EB),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SUB-WIDGETS & CUSTOM PAINTERS
// =============================================================================

/// Placeholder Tampilan Sorotan Kamera dengan Gambar Biji Kopi Statis
class _CameraPreviewPlaceholder extends StatelessWidget {
  final bool isLightOn;

  const _CameraPreviewPlaceholder({
    required this.isLightOn,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Latar Gambar Biji Kopi Dummy (Unsplash dengan Fallback Warna Gelap)
        Image.network(
          'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=1000&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF2C221E),
              child: const Center(
                child: Icon(
                  Icons.coffee_outlined,
                  size: 80,
                  color: Color(0xFF4A3A34),
                ),
              ),
            );
          },
        ),

        // Gradient & Vignette Gelap di Atas Gambar untuk Meniru Kamera Realistis
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: isLightOn ? 0.35 : 0.65),
                Colors.black.withValues(alpha: isLightOn ? 0.20 : 0.55),
                Colors.black.withValues(alpha: isLightOn ? 0.45 : 0.75),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol Circular Semi-Transparan untuk Atas Overlay
class _IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _IconButtonCircle({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2C231E).withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }
}

/// Panel Kontrol Bawah (Zoom, Shutter, Galeri, Flash & Catatan Kaki)
class _BottomControlPanel extends StatelessWidget {
  final String selectedZoom;
  final ValueChanged<String> onZoomChanged;
  final bool isFlashOn;
  final VoidCallback onFlashToggled;

  const _BottomControlPanel({
    required this.selectedZoom,
    required this.onZoomChanged,
    required this.isFlashOn,
    required this.onFlashToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF241A16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Selector Zoom (0.5x, 1x, 2x)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildZoomOption('0.5x'),
              const SizedBox(width: 16),
              _buildZoomOption('1x'),
              const SizedBox(width: 16),
              _buildZoomOption('2x'),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Baris Tombol Aksi (Galeri, Shutter, Flash)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tombol Galeri
              _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Galeri',
                onTap: () {},
              ),

              // Tombol Shutter Bulat Besar
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF4A342B),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5DDD5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tombol Flash (Mati / Nyala)
              _buildActionButton(
                icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: isFlashOn ? 'Nyala' : 'Mati',
                onTap: onFlashToggled,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Catatan Kaki Paling Bawah
          Text(
            'Roastmate hanya menilai biji yang terlihat pada permukaan foto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFFB8ACA0),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomOption(String zoomText) {
    final isSelected = selectedZoom == zoomText;
    return GestureDetector(
      onTap: () => onZoomChanged(zoomText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 44 : 38,
        height: isSelected ? 44 : 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7F4EE) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          zoomText,
          style: GoogleFonts.inter(
            color: isSelected ? const Color(0xFF1E1613) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: isSelected ? 14 : 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF382A23).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS UNTUK OVERLAY VIEWFINDER
// =============================================================================

/// Custom Painter untuk Menggambar 4 Siku Putih di Sudut Area Pemindaian
class ViewfinderCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-Left Corner ┌
    final topLeftPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(topLeftPath, paint);

    // Top-Right Corner ┐
    final topRightPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-Left Corner └
    final bottomLeftPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-Right Corner ┘
    final bottomRightPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter untuk Menggambar Dotted Target Circle dengan Titik Putih di Tengah
class TargetReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Menggambar lingkaran putus-putus (Dashed Circle)
    const int dashCount = 20;
    const double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        dashPaint,
      );
    }

    // Menggambar Titik Putih di Tengah Target Circle
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3.0, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
