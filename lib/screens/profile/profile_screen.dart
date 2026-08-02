import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/rating_breakdown.dart';
import '../../widgets/app_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _skills = [
    'House Painting',
    'Wall Tiling',
    'Plumbing Leak Repair',
    'Waterproofing',
  ];

  final TextEditingController _skillInputController = TextEditingController();

  @override
  void dispose() {
    _skillInputController.dispose();
    super.dispose();
  }

  void _openEditSkillsSheet() {
    showAppBottomSheet(
      context: context,
      title: 'Edit Active Skill Certifications',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD NEW SKILL',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _skillInputController,
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          color: AppColors.inkPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Electrical Repair',
                          fillColor: AppColors.canvas,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () {
                      final text = _skillInputController.text.trim();
                      if (text.isNotEmpty && !_skills.contains(text)) {
                        setState(() => _skills.add(text));
                        setSheetState(() {});
                        _skillInputController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.control,
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'CURRENT CERTIFIED SKILLS',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs + 2,
                runSpacing: AppSpacing.xs + 2,
                children: _skills.map((skill) {
                  return Chip(
                    backgroundColor: AppColors.surfaceRaised,
                    side: const BorderSide(color: AppColors.border),
                    label: Text(
                      skill,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    onDeleted: () {
                      setState(() => _skills.remove(skill));
                      setSheetState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'System Profile & Settings',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: User Profile Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: AppRadii.card,
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'RK',
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ramesh Kumar',
                                style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                          Text(
                            'Skilled Daily-Wage Worker',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          Text(
                            'Indiranagar, Bengaluru',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppColors.inkCaption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Trust Badges Row
                  const TrustBadgeRow(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 2: Rating Score & Review Breakdown
            const RatingBreakdown(
              average: 4.8,
              total: 24,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 3: Skills & Certifications Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE SKILLS & CERTIFICATIONS',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openEditSkillsSheet,
                        child: Text(
                          'Edit Skills ->',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs + 2,
                    children: [
                      ..._skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: AppRadii.control,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            skill,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: _openEditSkillsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandSubtle,
                            borderRadius: AppRadii.control,
                            border: Border.all(color: AppColors.brand),
                          ),
                          child: Text(
                            '+ Edit / Add',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 4: Workforce Dispatch Specs Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKFORCE DISPATCH SPECS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSpecRow('Expected Daily Rate', '₹650/day',
                      valueColor: AppColors.brand),
                  _buildSpecRow('Dispatch Radius', '15 km'),
                  _buildSpecRow('Preferred Shift', 'Morning (08:00 - 16:00)'),
                  _buildSpecRow('Payment Mode', 'Instant UPI / Cash',
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 5: System Reconfiguration Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYSTEM RECONFIGURATION',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionRow(
                    Icons.terminal_rounded,
                    'View System Gallery & Widgets',
                    onTap: () => context.push('/demo'),
                  ),
                  _buildActionRow(
                    Icons.palette_outlined,
                    'Toggle Dark/Warm Palette Tokens',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Warm dark mode tokens active.')),
                      );
                    },
                  ),
                  _buildActionRow(
                    Icons.cleaning_services_rounded,
                    'Clear Cached Dispatch Data',
                    isLast: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache purged cleanly.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 6: Account & Compliance Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT & COMPLIANCE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionRow(
                    Icons.badge_outlined,
                    'Aadhaar Document (Verified)',
                    trailingIcon: Icons.check_circle_rounded,
                    trailingColor: AppColors.success,
                  ),
                  _buildActionRow(
                    Icons.account_balance_outlined,
                    'Bank Account for Instant UPI Payout',
                  ),
                  _buildActionRow(
                    Icons.logout_rounded,
                    'Sign Out of Session',
                    textColor: AppColors.danger,
                    iconColor: AppColors.danger,
                    isLast: true,
                    onTap: () => context.go('/auth'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value,
      {Color? valueColor, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String label, {
    Color? textColor,
    Color? iconColor,
    IconData trailingIcon = Icons.chevron_right_rounded,
    Color? trailingColor,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? AppColors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
            Icon(
              trailingIcon,
              size: 16,
              color: trailingColor ?? AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
