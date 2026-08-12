import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../services/storage_service.dart';
import '../../services/completion_proof_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/completion_proof_provider.dart';

/// Opens the "Submit Completion Proof" bottom sheet for the assigned worker.
/// On successful submission: uploads photos, creates proof record, updates job status.
void openCompletionProofBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required String jobId,
  required String workerId,
  required String jobTitle,
  required VoidCallback onSubmitted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CompletionProofBottomSheet(
      jobId: jobId,
      workerId: workerId,
      jobTitle: jobTitle,
    ),
  ).then((_) {
    ref.invalidate(completionProofForJobProvider(jobId));
    ref.invalidate(jobDetailProvider(jobId));
    onSubmitted();
  });
}

class CompletionProofBottomSheet extends ConsumerStatefulWidget {
  final String jobId;
  final String workerId;
  final String jobTitle;

  const CompletionProofBottomSheet({
    super.key,
    required this.jobId,
    required this.workerId,
    required this.jobTitle,
  });

  @override
  ConsumerState<CompletionProofBottomSheet> createState() =>
      _CompletionProofBottomSheetState();
}

class _CompletionProofBottomSheetState
    extends ConsumerState<CompletionProofBottomSheet> {
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _confirmed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      setState(() => _errorMessage = 'Maximum 5 photos allowed.');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImages.add(picked);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not access photos. Please check permissions.');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedImages.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one photo as proof.');
      return;
    }
    if (!_confirmed) {
      setState(() => _errorMessage = 'Please confirm that the work has been completed.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload photos to storage
      final storageService = StorageService();
      final uploadedUrls = <String>[];

      for (final image in _selectedImages) {
        final url = await storageService.uploadCompletionProof(image, widget.jobId);
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          // Use a placeholder for demo/offline mode
          uploadedUrls.add('demo://completion/${widget.jobId}/${uploadedUrls.length}');
        }
      }

      if (uploadedUrls.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to upload photos. Please try again.';
        });
        return;
      }

      // 2. Create completion proof record
      final proofService = CompletionProofService();
      final proof = await proofService.submitProof(
        jobId: widget.jobId,
        workerId: widget.workerId,
        imageUrls: uploadedUrls,
      );

      if (proof == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to save proof. Please try again.';
        });
        return;
      }

      // 3. Update job status to proof_submitted
      final jobService = ref.read(jobServiceProvider);
      await jobService.updateWorkerProgress(
        jobId: widget.jobId,
        newStatus: 'proof_submitted',
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Submission failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSubtle,
                    borderRadius: AppRadii.control,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COMPLETE JOB',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        widget.jobTitle,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            // Proof section
            Text(
              'Upload proof of completed work',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add 1–5 clear photos showing the completed work. These will be reviewed by the employer.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.inkMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Image preview strip + Add button
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add photo button
                  if (_selectedImages.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.brandSubtle,
                          borderRadius: AppRadii.control,
                          border: Border.all(
                            color: AppColors.brand.withOpacity(0.4),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.brand,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ADD PHOTO',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Selected images
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.control,
                            border: Border.all(color: AppColors.brand),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            image.path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceRaised,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.inkMuted,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: AppSpacing.sm + 2,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_selectedImages.length}/5 photos added',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Confirmation checkbox
            GestureDetector(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _confirmed,
                      onChanged: (v) => setState(() => _confirmed = v ?? false),
                      activeColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'I confirm that this work has been completed as requested by the employer.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.inkPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerSubtle,
                  borderRadius: AppRadii.control,
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Demo disclaimer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningSubtle,
                borderRadius: AppRadii.control,
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DEMO: This is a simulated proof submission. No real files are transferred.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Submit CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'SUBMITTING...' : 'SUBMIT COMPLETION',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
