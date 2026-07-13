import 'package:attention_minder/module/payments/data/model/subscription_model.dart';
import 'package:attention_minder/module/payments/data/repository/payment_repository.dart';
import 'package:attention_minder/module/payments/presentation/screens/payment_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final int? lockedDay;

  const PaymentScreen({super.key, this.lockedDay});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF08112F);
  static const _muted = Color(0xFF68738F);
  static const _orange = Color(0xFFFFA300);
  static const _green = Color(0xFF31A322);
  static const _pageBackground = Color(0xFFFBFCFF);

  final PaymentRepository _repository = PaymentRepository();

  bool _isStartingCheckout = false;
  bool _isLoadingSubscription = true;
  bool _isWaitingForCheckoutReturn = false;
  bool _hasNavigatedToPaymentResult = false;
  SubscriptionModel? _subscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForCheckoutReturn) {
      _handleCheckoutReturn();
    }
  }

  Future<void> _loadSubscription({bool navigateOnActive = false}) async {
    setState(() {
      _isLoadingSubscription = true;
      _errorMessage = null;
    });

    try {
      final subscription = await _repository.getSubscription();
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
      });
      if (navigateOnActive) {
        _goToPaymentResult(PaymentResultStatus.success);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  Future<void> _startCheckout() async {
    setState(() {
      _isStartingCheckout = true;
      _errorMessage = null;
    });

    try {
      final session = await _repository.createCheckoutSession();
      final launched = await launchUrl(
        session.checkoutUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const PaymentException('Unable to open Stripe Checkout.');
      }

      if (!mounted) return;
      setState(() {
        _isWaitingForCheckoutReturn = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingCheckout = false;
        });
      }
    }
  }

  Future<void> _handleCheckoutReturn() async {
    if (!mounted || _hasNavigatedToPaymentResult) return;

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _hasNavigatedToPaymentResult) return;

    _goToPaymentResult(PaymentResultStatus.success);
  }

  void _goToPaymentResult(PaymentResultStatus status) {
    if (!mounted || _hasNavigatedToPaymentResult) return;

    _hasNavigatedToPaymentResult = true;
    _isWaitingForCheckoutReturn = false;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PaymentResultScreen(status: status)),
    );
  }

  Future<void> _openBillingPortal() async {
    setState(() {
      _isStartingCheckout = true;
      _errorMessage = null;
    });

    try {
      final uri = await _repository.createBillingPortalSession();
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const PaymentException('Unable to open billing portal.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingCheckout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final subscription = _subscription;
    final isActive = subscription?.isActive == true;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 560
                ? 520.0
                : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(),
                      const SizedBox(height: 28),
                      _lockBadge(),
                      const SizedBox(height: 18),
                      Text(
                        widget.lockedDay == null
                            ? 'Unlock your attention program'
                            : 'Unlock Day ${widget.lockedDay}',
                        style: _textStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Complete your secure Stripe checkout to access locked lessons, activities, and progress features.',
                        style: _textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _statusCard(subscription),
                      const SizedBox(height: 18),
                      _benefitTile(
                        icon: Icons.video_library_rounded,
                        title: 'All locked lessons',
                        subtitle: 'Continue the daily program without gaps.',
                      ),
                      _benefitTile(
                        icon: Icons.track_changes_rounded,
                        title: 'Daily activities',
                        subtitle: 'Goal setting, reflection, and guided tasks.',
                      ),
                      _benefitTile(
                        icon: Icons.verified_user_rounded,
                        title: 'Secure billing',
                        subtitle: 'Payments are handled by Stripe Checkout.',
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _errorBanner(_errorMessage!),
                      ],
                      const SizedBox(height: 26),
                      _primaryButton(
                        label: isActive
                            ? 'Manage subscription'
                            : 'Continue to secure checkout',
                        icon: isActive
                            ? Icons.manage_accounts_rounded
                            : Icons.lock_open_rounded,
                        isLoading: _isStartingCheckout,
                        onPressed: _isStartingCheckout
                            ? null
                            : isActive
                            ? _openBillingPortal
                            : _startCheckout,
                      ),
                      const SizedBox(height: 12),
                      _secondaryButton(),
                    ],
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
            onTap: () => Navigator.maybePop(context),
            customBorder: const CircleBorder(),
            child: Ink(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9ECF3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9D0DF).withValues(alpha: .35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
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
          'Payments',
          style: _textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _lockBadge() {
    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.lock_rounded, color: _orange, size: 30),
    );
  }

  Widget _statusCard(SubscriptionModel? subscription) {
    final isActive = subscription?.isActive == true;
    final status = subscription?.status ?? 'checking';
    final expiry = subscription?.currentPeriodEnd;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDDE3F2).withValues(alpha: .55),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE4F6E3)
                  : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _isLoadingSubscription
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _orange,
                    ),
                  )
                : Icon(
                    isActive
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: isActive ? _green : _muted,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Subscription active' : 'Subscription required',
                  style: _textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  expiry == null
                      ? 'Status: $status'
                      : 'Renews ${DateFormat('MMM d, yyyy').format(expiry)}',
                  style: _textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoadingSubscription ? null : _loadSubscription,
            icon: const Icon(Icons.refresh_rounded),
            color: _muted,
            tooltip: 'Refresh subscription',
          ),
        ],
      ),
    );
  }

  Widget _benefitTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: _textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          isLoading ? 'Opening...' : label,
          style: _textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
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
        onPressed: () => _loadSubscription(navigateOnActive: true),
        child: Text(
          'I already paid, refresh access',
          style: _textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
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
