import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';
import '../providers/user_provider.dart';
import 'app_bottom_sheet.dart';
import 'sticky_bottom_bar.dart';
import '../l10n/app_localizations.dart';

void openAddressBottomSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  showAppBottomSheet(
    context: context,
    title: l10n?.updateAddressSheetTitle ?? 'Update Primary Address',
    child: _AddressBottomSheetContent(ref: ref),
  );
}

class _AddressBottomSheetContent extends StatefulWidget {
  final WidgetRef ref;
  const _AddressBottomSheetContent({required this.ref});

  @override
  State<_AddressBottomSheetContent> createState() =>
      __AddressBottomSheetContentState();
}

class __AddressBottomSheetContentState
    extends State<_AddressBottomSheetContent> {
  late TextEditingController _streetController;
  late TextEditingController _localityController;
  late TextEditingController _cityController;

  static const List<Map<String, String>> _presets = [
    {
      'label': 'Home: Indiranagar',
      'street': 'Flat 302, Green Acres',
      'locality': 'Indiranagar',
      'city': 'BLR',
    },
    {
      'label': 'Office: HSR Layout',
      'street': 'Suite 104, Tech Park',
      'locality': 'HSR Layout',
      'city': 'BLR',
    },
    {
      'label': 'Studio: Koramangala',
      'street': 'Building 12, 5th Block',
      'locality': 'Koramangala',
      'city': 'BLR',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(userProfileProvider);
    _streetController = TextEditingController(text: user.streetAddress);
    _localityController = TextEditingController(text: user.locality);
    _cityController = TextEditingController(text: user.city);
  }

  @override
  void dispose() {
    _streetController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _streetController.text = preset['street']!;
      _localityController.text = preset['locality']!;
      _cityController.text = preset['city']!;
    });
  }

  void _saveAddress() {
    widget.ref.read(userProfileProvider.notifier).updateAddress(
          streetAddress: _streetController.text.trim(),
          locality: _localityController.text.trim(),
          city: _cityController.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Quick Location Presets',
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.inkMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((p) {
            final isCurrent = _localityController.text == p['locality'];
            return ActionChip(
              avatar: Icon(
                Icons.location_on_rounded,
                size: 14,
                color: isCurrent ? AppColors.brand : AppColors.inkMuted,
              ),
              label: Text(
                p['label']!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? AppColors.brand : AppColors.inkPrimary,
                ),
              ),
              onPressed: () => _applyPreset(p),
              backgroundColor: isCurrent ? AppColors.brandSubtle : AppColors.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.pill,
                side: BorderSide(
                  color: isCurrent ? AppColors.brand : AppColors.border,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Address Fields
        Text(
          l10n?.authStreetAddress ?? 'STREET ADDRESS',
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _streetController,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Flat 302, Green Acres Apartments',
            prefixIcon: Icon(Icons.home_outlined, size: 18, color: AppColors.inkMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.authLocality ?? 'LOCALITY / AREA *',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _localityController,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Indiranagar',
                      prefixIcon: Icon(Icons.map_outlined, size: 18, color: AppColors.inkMuted),
                    ),
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
                    l10n?.authCity ?? 'CITY *',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cityController,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkPrimary),
                    decoration: const InputDecoration(
                      hintText: 'BLR',
                      prefixIcon: Icon(Icons.location_city_rounded, size: 18, color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        StickyBottomBar(
          label: 'LOCATION UPDATE',
          price: _localityController.text.isEmpty
              ? 'Indiranagar'
              : '${_localityController.text}, ${_cityController.text}',
          ctaLabel: l10n?.saveAddressCta ?? 'SAVE ADDRESS',
          onCta: _saveAddress,
        ),
      ],
    );
  }
}
