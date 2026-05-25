import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExportView extends StatelessWidget {
  const ExportView({super.key, required this.viewModel});

  final ExportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Export Film',
          style: GoogleFonts.playfairDisplay(color: AppTheme.cream),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectSummary(),
                const SizedBox(height: 28),
                if (viewModel.status == ExportStatus.idle) ...[
                  _buildResolutionPicker(),
                  const SizedBox(height: 32),
                  _buildExportButton(context),
                ] else if (viewModel.isExporting) ...[
                  _buildExportingState(),
                ] else if (viewModel.isDone) ...[
                  _buildDoneState(context),
                ] else if (viewModel.status == ExportStatus.error) ...[
                  _buildErrorState(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectSummary() {
    final project = viewModel.project;
    final duration = project.totalDurationSeconds;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final durationStr = minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_creation_outlined,
                  color: AppTheme.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.title,
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.cream,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoChip(
                icon: Icons.photo_library_outlined,
                label: '${project.slideCount} slides',
              ),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: durationStr,
              ),
              if (project.musicName != null) ...[
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.music_note_outlined,
                  label: project.musicName!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text(
              'Output Quality',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.cream,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ExportResolution.values.map((res) {
          final isSelected = viewModel.resolution == res;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => viewModel.setResolution(res),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.gold.withValues(alpha: 0.1)
                      : AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.gold : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppTheme.gold : AppTheme.subtleText,
                          width: 2,
                        ),
                        color: isSelected ? AppTheme.gold : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: AppTheme.darkBg, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.label,
                            style: GoogleFonts.lato(
                              color: AppTheme.cream,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          Text(
                            _resolutionDescription(res),
                            style: GoogleFonts.lato(
                              color: AppTheme.subtleText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (res == ExportResolution.fullHd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Recommended',
                          style: GoogleFonts.lato(
                              color: AppTheme.gold, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _resolutionDescription(ExportResolution res) {
    switch (res) {
      case ExportResolution.hd:
        return 'Good for sharing on mobile';
      case ExportResolution.fullHd:
        return 'Great for TV and displays';
      case ExportResolution.fourK:
        return 'Best for cinema-quality output';
    }
  }

  Widget _buildExportButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.movie_creation_outlined, size: 20),
            label: const Text('Export to MP4'),
            onPressed: viewModel.startExport,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The video will be saved to your device',
          style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExportingState() {
    final percent = (viewModel.progress * 100).round();
    return Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: viewModel.progress,
                strokeWidth: 6,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ),
            Column(
              children: [
                Text(
                  '$percent%',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.cream,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Rendering your wedding film...',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.cream,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getExportMessage(viewModel.progress),
          style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: viewModel.progress,
            minHeight: 6,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
          ),
        ),
      ],
    );
  }

  String _getExportMessage(double progress) {
    if (progress < 0.2) return 'Processing photos and transitions...';
    if (progress < 0.5) return 'Compositing slides...';
    if (progress < 0.8) return 'Adding music and effects...';
    if (progress < 0.95) return 'Encoding to MP4...';
    return 'Finalising...';
  }

  Widget _buildDoneState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.gold.withValues(alpha: 0.15),
            border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.gold, size: 52),
        ),
        const SizedBox(height: 20),
        Text(
          'Export Complete!',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.cream,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your wedding film is ready',
          style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (viewModel.outputPath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined,
                    color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewModel.outputPath!,
                    style: GoogleFonts.lato(
                        color: AppTheme.subtleText, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
                onPressed: () => _showShareMessage(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.save_alt_outlined, size: 18),
                label: const Text('Save'),
                onPressed: () => _showSaveMessage(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: viewModel.reset,
          child: Text('Export Again',
              style: GoogleFonts.lato(color: AppTheme.subtleText)),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 64),
        const SizedBox(height: 16),
        Text(
          viewModel.error ?? 'Export failed',
          style: GoogleFonts.lato(color: AppTheme.cream, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: viewModel.reset,
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  void _showShareMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share functionality requires platform integration',
          style: GoogleFonts.lato(),
        ),
        backgroundColor: AppTheme.darkSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSaveMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Film saved to ${viewModel.outputPath}',
          style: GoogleFonts.lato(),
        ),
        backgroundColor: AppTheme.darkSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.lato(
                color: AppTheme.subtleText,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
