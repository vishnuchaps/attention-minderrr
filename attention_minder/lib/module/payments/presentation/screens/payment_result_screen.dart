import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:attention_minder/module/payments/data/model/subscription_model.dart';
import 'package:attention_minder/module/payments/data/repository/payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PaymentResultStatus { success, failed }

class PaymentResultScreen extends StatefulWidget {
  final PaymentResultStatus status;

  const PaymentResultScreen({super.key, required this.status});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  static const _ink = Color(0xFF08112F);
  static const _muted = Color(0xFF67738F);
  static const _success = Color(0xFF19A65A);
  static const _failed = Color(0xFFE15151);
  static const _blue = Color(0xFF1479FF);
  static const _pageBackground = Color(0xFFF8FBFF);
  static const _line = Color(0xFFE2EAF5);

  final PaymentRepository _repository = PaymentRepository();

  bool _isChecking = true;
  SubscriptionModel? _subscription;
  String? _errorMessage;

  bool get _isSuccessReturn => widget.status == PaymentResultStatus.success;

  bool get _hasActiveAccess => _subscription?.isActive == true;

  Color get _accent => _isSuccessReturn ? _success : _failed;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final subscription = await _repository.getSubscription();
      if (!mounted) return;
      setState(() => _subscription = subscription);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 370;
            final maxWidth = constraints.maxWidth > 560
                ? 520.0
                : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 22,
                    compact ? 18 : 24,
                    compact ? 18 : 22,
                    safeBottom + 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          safeBottom -
                          (compact ? 42 : 48),
                    ),
                    child: Column(
                      children: [
                        _topBar(),
                        SizedBox(height: compact ? 34 : 48),
                        _heroMark(compact: compact),
                        SizedBox(height: compact ? 26 : 30),
                        _titleBlock(compact: compact),
                        SizedBox(height: compact ? 22 : 28),
                        _statusCard(compact: compact),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _errorBanner(_errorMessage!),
                        ],
                        SizedBox(height: compact ? 24 : 30),
                        _detailsCard(compact: compact),
                        SizedBox(height: compact ? 28 : 34),
                        _primaryButton(),
                        const SizedBox(height: 12),
                        _secondaryButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: Ink(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9D4E8).withValues(alpha: .26),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: _ink,
                size: 30,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Payment',
          style: _textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _heroMark({required bool compact}) {
    final size = compact ? 116.0 : 132.0;
    final innerSize = compact ? 78.0 : 88.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: .08),
          ),
        ),
        Container(
          width: size * .78,
          height: size * .78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: .12),
          ),
        ),
        Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: .28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            _isSuccessReturn ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: compact ? 42 : 48,
          ),
        ),
      ],
    );
  }

  Widget _titleBlock({required bool compact}) {
    return Column(
      children: [
        Text(
          _title,
          textAlign: TextAlign.center,
          style: _textStyle(
            fontSize: compact ? 25 : 29,
            fontWeight: FontWeight.w900,
            color: _ink,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: _textStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: _muted,
            height: 1.42,
          ),
        ),
      ],
    );
  }

  String get _title {
    if (!_isSuccessReturn) {
      return 'Payment not completed';
    }

    if (_isChecking) {
      return 'Confirming your payment';
    }

    return _hasActiveAccess ? 'Payment successful' : 'Payment received';
  }

  String get _subtitle {
    if (!_isSuccessReturn) {
      return 'Your checkout was cancelled or did not finish. You can try again whenever you are ready.';
    }

    if (_isChecking) {
      return 'You are back in the app. We are checking your access with the server.';
    }

    return _hasActiveAccess
        ? 'Your access is unlocked. Continue your attention program without losing your place.'
        : 'Stripe returned successfully. Access may take a few seconds to update.';
  }

  Widget _statusCard({required bool compact}) {
    final statusText = _isChecking
        ? 'Checking status'
        : _hasActiveAccess
        ? 'Access active'
        : _isSuccessReturn
        ? 'Confirmation pending'
        : 'Checkout cancelled';
    final detailText = _isChecking
        ? 'Please wait while we sync your payment.'
        : _hasActiveAccess
        ? 'Your subscription is active on this account.'
        : _isSuccessReturn
        ? 'Refresh once if you just completed payment.'
        : 'No payment was completed for this attempt.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: compact ? 44 : 48,
            height: compact ? 44 : 48,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _isChecking
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _accent,
                    ),
                  )
                : Icon(
                    _hasActiveAccess
                        ? Icons.verified_rounded
                        : _isSuccessReturn
                        ? Icons.schedule_rounded
                        : Icons.receipt_long_outlined,
                    color: _accent,
                    size: compact ? 23 : 25,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: _textStyle(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detailText,
                  style: _textStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard({required bool compact}) {
    final rows = _isSuccessReturn
        ? const [
            _PaymentInfoRowData(
              icon: Icons.lock_open_rounded,
              title: 'Secure checkout',
              value: 'Completed through Stripe',
            ),
            _PaymentInfoRowData(
              icon: Icons.sync_rounded,
              title: 'Access sync',
              value: 'Verified with your account',
            ),
          ]
        : const [
            _PaymentInfoRowData(
              icon: Icons.shield_outlined,
              title: 'No access changed',
              value: 'Your account remains protected',
            ),
            _PaymentInfoRowData(
              icon: Icons.refresh_rounded,
              title: 'Try again',
              value: 'Start checkout when ready',
            ),
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _PaymentInfoRow(data: rows[index], accent: _accent),
            if (index != rows.length - 1)
              const Divider(height: 22, color: _line),
          ],
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Text(
        message,
        style: _textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFC83737),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _primaryButton() {
    final canContinue = _hasActiveAccess;
    final label = canContinue ? 'Continue program' : 'Refresh status';
    final icon = canContinue
        ? Icons.arrow_forward_rounded
        : Icons.refresh_rounded;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isChecking
            ? null
            : canContinue
            ? _continueProgram
            : _refreshStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: canContinue ? _success : _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accent.withValues(alpha: .42),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isChecking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 21),
        label: Text(
          _isChecking ? 'Checking...' : label,
          style: _textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: Text(
          _hasActiveAccess ? 'Back' : 'Back to payment',
          style: _textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
      ),
    );
  }

  void _continueProgram() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AttentionProgramOverviewScreen()),
      (route) => route.isFirst,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFB8C7DD).withValues(alpha: .15),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static TextStyle _textStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _ink,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final _PaymentInfoRowData data;
  final Color accent;

  const _PaymentInfoRow({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(data.icon, color: accent, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            data.title,
            style: _PaymentResultScreenState._textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _PaymentResultScreenState._ink,
            ),
          ),
        ),
        Flexible(
          child: Text(
            data.value,
            textAlign: TextAlign.right,
            style: _PaymentResultScreenState._textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PaymentResultScreenState._muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentInfoRowData {
  final IconData icon;
  final String title;
  final String value;

  const _PaymentInfoRowData({
    required this.icon,
    required this.title,
    required this.value,
  });
}
