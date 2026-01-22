/// 📝 GIGMATCH Gig Contract Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass contract sections
/// - Digital signature canvas
/// - Animated terms checkboxes
/// - Progress tracking
/// - PDF preview integration
///
/// Professional contract management for gigs
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📝 CONTRACT SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class GigContractScreen extends StatefulWidget {
  final String? gigId;
  final String? contractId;
  
  const GigContractScreen({super.key, this.gigId, this.contractId});

  @override
  State<GigContractScreen> createState() => _GigContractScreenState();
}

class _GigContractScreenState extends State<GigContractScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoading = false;
  bool _hasSignature = false;

  // Agreement checkboxes
  final Map<String, bool> _agreements = {
    'terms': false,
    'cancellation': false,
    'payment': false,
    'liability': false,
    'conduct': false,
  };

  // Mock contract data
  final _contract = ContractData(
    id: 'CTR-20240125-001',
    gigTitle: 'Saturday Night Jazz Performance',
    venueName: 'The Velvet Lounge',
    artistName: 'Marcus Cole',
    date: DateTime.now().add(const Duration(days: 14)),
    startTime: '8:00 PM',
    endTime: '11:00 PM',
    compensation: 350.00,
    depositAmount: 100.00,
    depositDue: DateTime.now().add(const Duration(days: 7)),
    cancellationPolicy: '48 hours notice required for full refund',
    requirements: [
      '2 x 45-minute sets with 15-minute break',
      'Professional attire required',
      'Arrive by 6:00 PM for sound check',
      'Bring own instruments (piano provided)',
    ],
    venueProvides: [
      'Professional PA system',
      'Grand piano',
      'Lighting setup',
      'Green room access',
      'One meal and beverages',
      'Free parking',
    ],
    status: ContractStatus.pending,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _allTermsAccepted => _agreements.values.every((v) => v);

  Future<void> _signContract() async {
    if (!_allTermsAccepted || !_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept all terms and sign'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Dialog(
          backgroundColor: AppColors.surface(brightness),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const AnimatedSuccessCheck(size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contract Signed!',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your contract has been signed and sent to the venue. You\'ll receive a confirmation email shortly.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildAppBar(brightness),

            // Contract Header
            SliverToBoxAdapter(
              child: _buildContractHeader(brightness),
            ),

            // Progress Steps
            SliverToBoxAdapter(
              child: _buildProgressSteps(brightness),
            ),

            // Content based on step
            SliverToBoxAdapter(
              child: _buildCurrentStepContent(brightness),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(brightness),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Brightness brightness) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.lightImpact();
          _showExitConfirmation(brightness);
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Icon(
            Icons.close_rounded,
            color: AppColors.text(brightness),
          ),
        ),
      ),
      title: Text(
        'Gig Contract',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.text(brightness),
        ),
      ),
      actions: [
        AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.selectionClick();
            _showContractPreview(brightness);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.crimson,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 CONTRACT HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContractHeader(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: AppColors.crimson,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contract.gigTitle,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contract.venueName,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(brightness),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildInfoItem(
                  Icons.calendar_today_rounded,
                  _formatDate(_contract.date),
                  brightness,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.border(brightness),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                _buildInfoItem(
                  Icons.schedule_rounded,
                  '${_contract.startTime} - ${_contract.endTime}',
                  brightness,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.border(brightness),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                _buildInfoItem(
                  Icons.payments_rounded,
                  '\$${_contract.compensation.toStringAsFixed(0)}',
                  brightness,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Pending Signature',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Brightness brightness) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSec(brightness)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 PROGRESS STEPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressSteps(Brightness brightness) {
    final steps = ['Review', 'Terms', 'Sign'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < _currentStep
                    ? AppColors.crimson
                    : AppColors.border(brightness),
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == _currentStep;
            final isCompleted = stepIndex < _currentStep;

            return AnimatedTapFeedback(
              onTap: () {
                if (stepIndex <= _currentStep) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep = stepIndex);
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.crimson
                          : (isActive
                              ? AppColors.crimson.withValues(alpha: 0.15)
                              : AppColors.surface(brightness)),
                      border: Border.all(
                        color: isActive || isCompleted
                            ? AppColors.crimson
                            : AppColors.border(brightness),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.crimson
                                    : AppColors.textSec(brightness),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[stepIndex],
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? AppColors.text(brightness)
                          : AppColors.textSec(brightness),
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📄 STEP CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCurrentStepContent(Brightness brightness) {
    switch (_currentStep) {
      case 0:
        return _buildReviewStep(brightness);
      case 1:
        return _buildTermsStep(brightness);
      case 2:
        return _buildSignStep(brightness);
      default:
        return const SizedBox();
    }
  }

  // Step 1: Review
  Widget _buildReviewStep(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Contract Details',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Artist Requirements
          _ContractSection(
            title: 'Artist Requirements',
            icon: Icons.person_rounded,
            items: _contract.requirements,
            brightness: brightness,
          ),

          const SizedBox(height: 16),

          // Venue Provides
          _ContractSection(
            title: 'Venue Provides',
            icon: Icons.business_rounded,
            items: _contract.venueProvides,
            brightness: brightness,
          ),

          const SizedBox(height: 16),

          // Payment Terms
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Terms',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PaymentRow(
                  label: 'Total Compensation',
                  value: '\$${_contract.compensation.toStringAsFixed(2)}',
                  brightness: brightness,
                ),
                _PaymentRow(
                  label: 'Deposit Due',
                  value:
                      '\$${_contract.depositAmount.toStringAsFixed(2)} by ${_formatDate(_contract.depositDue)}',
                  brightness: brightness,
                ),
                _PaymentRow(
                  label: 'Remaining Balance',
                  value:
                      '\$${(_contract.compensation - _contract.depositAmount).toStringAsFixed(2)} on gig day',
                  brightness: brightness,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _contract.cancellationPolicy,
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Terms
  Widget _buildTermsStep(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Accept Terms & Conditions',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please read and accept all terms before signing',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          _AgreementCheckbox(
            title: 'Terms & Conditions',
            description:
                'I have read and agree to the GigMatch Terms of Service and Contract Terms.',
            isChecked: _agreements['terms']!,
            onChanged: (v) => setState(() => _agreements['terms'] = v),
            brightness: brightness,
          ),

          _AgreementCheckbox(
            title: 'Cancellation Policy',
            description:
                'I understand and accept the cancellation policy: ${_contract.cancellationPolicy}',
            isChecked: _agreements['cancellation']!,
            onChanged: (v) => setState(() => _agreements['cancellation'] = v),
            brightness: brightness,
          ),

          _AgreementCheckbox(
            title: 'Payment Agreement',
            description:
                'I agree to the payment terms and understand that final payment will be processed after the gig.',
            isChecked: _agreements['payment']!,
            onChanged: (v) => setState(() => _agreements['payment'] = v),
            brightness: brightness,
          ),

          _AgreementCheckbox(
            title: 'Liability Waiver',
            description:
                'I acknowledge that I am responsible for my own equipment and GigMatch is not liable for damages.',
            isChecked: _agreements['liability']!,
            onChanged: (v) => setState(() => _agreements['liability'] = v),
            brightness: brightness,
          ),

          _AgreementCheckbox(
            title: 'Code of Conduct',
            description:
                'I agree to maintain professional conduct and follow venue rules during the gig.',
            isChecked: _agreements['conduct']!,
            onChanged: (v) => setState(() => _agreements['conduct'] = v),
            brightness: brightness,
          ),

          const SizedBox(height: 16),

          // Accept all button
          Center(
            child: AnimatedTapFeedback(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  final newValue = !_allTermsAccepted;
                  _agreements.updateAll((key, value) => newValue);
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.crimson),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _allTermsAccepted ? 'Deselect All' : 'Accept All Terms',
                  style: const TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Sign
  Widget _buildSignStep(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Digital Signature',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign below to complete the contract',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Signature Canvas
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasSignature
                    ? AppColors.success
                    : AppColors.border(brightness),
                width: _hasSignature ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Canvas
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _SignatureCanvas(
                    onSignatureChanged: (hasSignature) {
                      setState(() => _hasSignature = hasSignature);
                    },
                  ),
                ),

                // Placeholder text
                if (!_hasSignature)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.draw_rounded,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign here',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Clear button
                if (_hasSignature)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedTapFeedback(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _hasSignature = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.clear_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: AppColors.textSec(brightness),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signing as',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _contract.artistName,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.today_rounded,
                  color: AppColors.textSec(brightness),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDate(DateTime.now()),
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legal notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By signing, you acknowledge that this is a legally binding contract.',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎛️ BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar(Brightness brightness) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        border: Border(
          top: BorderSide(color: AppColors.border(brightness)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text(brightness),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < 2
                ? ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _currentStep++);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _signContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign Contract',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showExitConfirmation(Brightness brightness) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave Contract?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'Your progress will be saved. You can continue signing later.',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Stay',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }

  void _showContractPreview(Brightness brightness) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF preview coming soon!'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📄 CONTRACT SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _ContractSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Brightness brightness;

  const _ContractSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 14,
                        height: 1.4,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// 💰 PAYMENT ROW
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Brightness brightness;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ✅ AGREEMENT CHECKBOX
// ═══════════════════════════════════════════════════════════════════════════

class _AgreementCheckbox extends StatelessWidget {
  final String title;
  final String description;
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final Brightness brightness;

  const _AgreementCheckbox({
    required this.title,
    required this.description,
    required this.isChecked,
    required this.onChanged,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!isChecked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChecked
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isChecked ? AppColors.success : AppColors.border(brightness),
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isChecked
                      ? AppColors.success
                      : AppColors.textSec(brightness),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ✍️ SIGNATURE CANVAS
// ═══════════════════════════════════════════════════════════════════════════

class _SignatureCanvas extends StatefulWidget {
  final ValueChanged<bool> onSignatureChanged;

  const _SignatureCanvas({required this.onSignatureChanged});

  @override
  State<_SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<_SignatureCanvas> {
  final List<List<Offset>> _lines = [];
  List<Offset> _currentLine = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentLine = [details.localPosition];
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentLine.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        if (_currentLine.isNotEmpty) {
          _lines.add(List.from(_currentLine));
          _currentLine = [];
          widget.onSignatureChanged(true);
        }
      },
      child: CustomPaint(
        painter: _SignaturePainter(
          lines: _lines,
          currentLine: _currentLine,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;
  final List<Offset> currentLine;

  _SignaturePainter({required this.lines, required this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      _drawLine(canvas, line, paint);
    }

    _drawLine(canvas, currentLine, paint);
  }

  void _drawLine(Canvas canvas, List<Offset> line, Paint paint) {
    if (line.length < 2) return;

    final path = Path();
    path.moveTo(line.first.dx, line.first.dy);

    for (int i = 1; i < line.length; i++) {
      path.lineTo(line[i].dx, line[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum ContractStatus { pending, signed, countersigned, completed, cancelled }

class ContractData {
  final String id;
  final String gigTitle;
  final String venueName;
  final String artistName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double compensation;
  final double depositAmount;
  final DateTime depositDue;
  final String cancellationPolicy;
  final List<String> requirements;
  final List<String> venueProvides;
  final ContractStatus status;

  const ContractData({
    required this.id,
    required this.gigTitle,
    required this.venueName,
    required this.artistName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.compensation,
    required this.depositAmount,
    required this.depositDue,
    required this.cancellationPolicy,
    required this.requirements,
    required this.venueProvides,
    required this.status,
  });
}
