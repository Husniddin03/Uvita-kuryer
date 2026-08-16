import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../widgets/app_buttons.dart';
import 'not_found_screen.dart';

/// Yetkazish PIN ekrani — dizayn: pin_va_yakunlash/
class PinScreen extends StatefulWidget {
  final Order order;
  const PinScreen({super.key, required this.order});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(4, (_) => FocusNode());

  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _ctrls.map((c) => c.text).join();

  void _onDigit(String v, int index) {
    setState(() => _error = null);
    if (v.length == 1 && index < 3) {
      _focuses[index + 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_pin.length < 4) {
      setState(() => _error = '4 xonali kodni to\'liq kiriting');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<OrderProvider>().deliver(widget.order, pin: _pin);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
      // Noto'g'ri PIN — tozalab qayta kiritish
      for (final c in _ctrls) {
        c.clear();
      }
      _focuses.first.requestFocus();
    }
  }

  void _openNotFound() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotFoundScreen(order: widget.order),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 20, color: AppColors.textMain),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Buyurtmani yakunlash',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Dialpad ikonkasi
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.infoBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.dialpad,
                            size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Yetkazish PIN kodini kiriting',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mijoz ilovasidagi 4 xonali tasdiqlash kodini kiriting.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── PIN qutilari ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++) ...[
                            if (i > 0) const SizedBox(width: 14),
                            SizedBox(
                              width: 62,
                              height: 70,
                              child: TextField(
                                controller: _ctrls[i],
                                focusNode: _focuses[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: EdgeInsets.zero,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.6),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                onChanged: (v) => _onDigit(v, i),
                                onTap: () => _ctrls[i].selection =
                                    TextSelection.collapsed(
                                        offset: _ctrls[i].text.length),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Tasdiqlash',
                        loading: _submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _submitting ? null : _openNotFound,
                        icon: const Icon(Icons.person_search_outlined,
                            size: 20, color: AppColors.error),
                        label: const Text(
                          'Mijoz topilmadi?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Muvaffaqiyat modali ──
          if (_success)
            Positioned.fill(
              child: _SuccessModal(
                fee: widget.order.courierFee,
                onFinish: _finish,
              ),
            ),
        ],
      ),
    );
  }
}

/// Muvaffaqiyat modali — check animatsiyasi + daromad.
class _SuccessModal extends StatelessWidget {
  final int fee;
  final VoidCallback onFinish;

  const _SuccessModal({required this.fee, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 48,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ping animatsiyali check
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) => Transform.scale(
                      scale: t,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle,
                            size: 56, color: AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Muvaffaqiyatli!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Buyurtma egasiga yetkazildi.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Daromad
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'DAROMAD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatMoney(fee),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Yakunlash', onPressed: onFinish),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
