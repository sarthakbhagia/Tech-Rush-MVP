import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../providers/user_provider.dart';
import 'app_bottom_sheet.dart';

void openPostJobBottomSheet(BuildContext context, WidgetRef ref, {String? initialCategory}) {
  showAppBottomSheet(
    context: context,
    title: 'Post Daily Dispatch Job',
    child: _PostJobBottomSheetContent(ref: ref, initialCategory: initialCategory),
  );
}

class _PostJobBottomSheetContent extends StatefulWidget {
  final WidgetRef ref;
  final String? initialCategory;

  const _PostJobBottomSheetContent({required this.ref, this.initialCategory});

  @override
  State<_PostJobBottomSheetContent> createState() =>
      __PostJobBottomSheetContentState();
}

class __PostJobBottomSheetContentState
    extends State<_PostJobBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late String _selectedCategory;
  bool _isUrgent = false;
  bool _isPosting = false;
  String? _errorMessage;

  static const List<String> _categories = [
    'Painting',
    'Cleaning',
    'Plumbing',
    'Cooking',
    'Gardening',
    'Electrical',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? _categories.first;
    final user = widget.ref.read(userProfileProvider);
    _locationController.text = '${user.locality}, ${user.city}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handlePostJob() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final location = _locationController.text.trim();
    final user = widget.ref.read(userProfileProvider);

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    final newJob = Job(
      id: '',
      title: title,
      category: _selectedCategory,
      description: desc,
      wage: price,
      originalWage: price > 0 ? price * 1.15 : null,
      status: 'open',
      rating: 5.0,
      reviewCount: 0,
      location: location.isNotEmpty ? location : user.shortAddress,
      date: 'Today',
      employerName: user.name.isNotEmpty ? user.name : 'Employer',
      urgent: _isUrgent,
      verified: true,
    );

    final created =
        await widget.ref.read(jobServiceProvider).createJob(newJob);

    if (mounted) {
      setState(() => _isPosting = false);

      if (created != null) {
        widget.ref.invalidate(jobsByCategoryProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Job "$title" posted successfully!',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Failed to post job. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: AppRadii.control,
                border: Border.all(color: AppColors.danger),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Category Selector
          Text(
            'CATEGORY *',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat, style: GoogleFonts.inter(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Job Title
          Text(
            'JOB TITLE *',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. 3 BHK Interior Wall Painting',
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Please enter job title' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            'DESCRIPTION *',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
            decoration: const InputDecoration(
              hintText: 'Provide task details, tools available, requirements...',
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Please enter description' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Price & Location Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY WAGE (₹) *',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.spaceMono(fontSize: 13, color: AppColors.inkPrimary),
                      decoration: const InputDecoration(
                        hintText: '1200',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCATION *',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Indiranagar, Stage 2',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Urgent Switch
          SwitchListTile(
            title: Text(
              'Mark as Urgent Dispatch',
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Highlights posting for immediate worker bids',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
            ),
            value: _isUrgent,
            activeColor: AppColors.brand,
            onChanged: (val) => setState(() => _isUrgent = val),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Submit CTA
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _handlePostJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Publish Job Posting',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
