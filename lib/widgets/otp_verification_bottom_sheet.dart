import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/spacing.dart';
import '../core/utils/formatters.dart';
import '../providers/user_provider.dart';
import 'app_bottom_sheet.dart';

void openOtpVerificationBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String phone,
  String? fullName,
  String? streetAddress,
  String? locality,
  String? city,
  bool isDemoMode = false,
}) {
  showAppBottomSheet(
    context: context,
    title: 'Verify Mobile Security OTP',
    child: OtpVerificationWidget(
      phone: phone,
      fullName: fullName,
      streetAddress: streetAddress,
      locality: locality,
      city: city,
      isDemoMode: isDemoMode,
    ),
  );
}

class OtpVerificationWidget extends ConsumerStatefulWidget {
  final String phone;
  final String? fullName;
  final String? streetAddress;
  final String? locality;
  final String? city;
  final bool isDemoMode;

  const OtpVerificationWidget({
    super.key,
    required this.phone,
    this.fullName,
    this.streetAddress,
    this.locality,
    this.city,
    this.isDemoMode = false,
  });

  @override
  ConsumerState<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends ConsumerState<OtpVerificationWidget> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpToken => Formatters.toWesternDigits(
        _controllers.map((c) => c.text).join(),
      );

  Future<void> _verifyOtp() async {
    final token = _otpToken.trim();
    if (token.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of your OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(userProfileProvider.notifier).verifyMobileOtp(
            phone: widget.phone,
            token: token,
            fullName: widget.fullName,
            streetAddress: widget.streetAddress,
            locality: widget.locality,
            city: widget.city,
            isDemoMode: widget.isDemoMode,
          );

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid or expired OTP code. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(userProfileProvider.notifier).sendMobileOtp(phone: widget.phone);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP code resent to your mobile number.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to resend OTP: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone =
        widget.phone.startsWith('+') ? widget.phone : '+91 ${widget.phone}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit authorization code dispatched to:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              displayPhone,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Change Number',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: AppRadii.control,
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 6 Pin Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                inputFormatters: const [
                  WesternDigitsTextInputFormatter(),
                ],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.spaceMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  fillColor: AppColors.surfaceRaised,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.control,
                    borderSide: const BorderSide(color: AppColors.brand, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                  if (_otpToken.length == 6) {
                    _verifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _resendCountdown > 0
                  ? 'Resend OTP in ${_resendCountdown}s'
                  : 'Didn\'t receive code?',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
            ),
            GestureDetector(
              onTap: _resendCountdown == 0 ? _resendOtp : null,
              child: Text(
                'RESEND NOW',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _resendCountdown == 0 ? AppColors.brand : AppColors.inkCaption,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Submit Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Verify & Proceed',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
