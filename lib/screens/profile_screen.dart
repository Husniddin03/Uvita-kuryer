import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import 'notifications_screen.dart';

/// Profil — dizayn: profil/
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _togglingOnline = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await OrderService.getProfile();
      if (!mounted) return;
      context.read<AuthProvider>().updateProfile(p);
    } catch (_) {
      // Profil o'zgarmasa — sessiyadagi ma'lumot yetarli
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _togglingOnline = true);
    try {
      final res = await OrderService.setAvailability(value);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final cur = auth.profile;
      if (cur != null) {
        auth.updateProfile(cur.copyWith(
          isOnline: res.isOnline,
          shiftStartedAt: res.shiftStartedAt ?? cur.shiftStartedAt,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chiqish',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Tizimdan chiqasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AuthProvider>().logout();
    }
  }

  static const _supportCategories = [
    ('delivery', 'Yetkazib berish'),
    ('customer', 'Mijoz bilan muammo'),
    ('vehicle', 'Transport'),
    ('accident', 'Baxtsiz hodisa'),
    ('app', 'Ilova xatosi'),
    ('other', 'Boshqa'),
  ];

  /// Qo'llab-quvvatlash — murojaat yuborish + tarixi.
  Future<void> _openSupport() async {
    final category = ValueNotifier<String>('delivery');
    final message = TextEditingController();
    final sending = ValueNotifier<bool>(false);
    final history = ValueNotifier<List<Map<String, dynamic>>>([]);

    // Tarixni yuklash
    try {
      history.value = await OrderService.getSupport();
    } catch (_) {}

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 36,
                height: 5,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Qo\'llab-quvvatlash',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 14),
              // Murojaatlar tarixi
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: history,
                builder: (context, tickets, _) {
                  if (tickets.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mening murojaatlarim',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView.separated(
                          controller: scrollController,
                          shrinkWrap: true,
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final t = tickets[i];
                            final status = (t['status'] ?? 'open') as String;
                            final isResolved = status == 'resolved' ||
                                status == 'closed';
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isResolved
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Murojaat #${t['id']} · ${_categoryLabel((t['category'] ?? '') as String)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        isResolved ? 'Hal qilindi' : 'Jarayonda',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isResolved
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (t['message'] ?? '') as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if ((t['admin_reply'] ?? '') != '') ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '💬 ${t['admin_reply']}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 14),
                    ],
                  );
                },
              ),
              // Kategoriya tanlash
              ValueListenableBuilder<String>(
                valueListenable: category,
                builder: (context, cat, _) => DropdownButtonFormField<String>(
                  initialValue: cat,
                  decoration: const InputDecoration(labelText: 'Mavzu'),
                  items: [
                    for (final (code, label) in _supportCategories)
                      DropdownMenuItem(value: code, child: Text(label)),
                  ],
                  onChanged: (v) {
                    if (v != null) category.value = v;
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Xabar',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: sending,
                builder: (context, isSending, _) => FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          sending.value = true;
                          try {
                            await OrderService.createSupport(
                              category: category.value,
                              message: message.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Murojaat yuborildi. Tez orada javob beramiz.')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            sending.value = false;
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Yuborish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    message.dispose();
    sending.dispose();
  }

  String _categoryLabel(String code) {
    for (final (c, label) in _supportCategories) {
      if (c == code) return label;
    }
    return code;
  }

  String _vehicleLabel(String code) {
    switch (code) {
      case 'foot':
        return 'Piyoda';
      case 'bicycle':
        return 'Velosiped';
      case 'motorcycle':
        return 'Mototsikl';
      case 'car':
        return 'Avtomobil';
      default:
        return code;
    }
  }

  /// Profilni tahrirlash — PUT /courier/profile.
  Future<void> _editProfile() async {
    final auth = context.read<AuthProvider>();
    final cur = auth.profile;
    final nameCtrl =
        TextEditingController(text: cur?.name ?? '');
    final phoneCtrl = TextEditingController(text: cur?.phone ?? '');
    final vehicleNumCtrl =
        TextEditingController(text: cur?.vehicleNumber ?? '');
    final vehicleType = ValueNotifier<String>(
        cur?.vehicleType.isNotEmpty == true ? cur!.vehicleType : 'car');
    final saving = ValueNotifier<bool>(false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 5,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profilni tahrirlash',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Ism',
                hintText: 'Ismingiz',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '+998901234567',
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: vehicleType,
              builder: (context, vt, _) => DropdownButtonFormField<String>(
                initialValue: vt,
                decoration: const InputDecoration(labelText: 'Transport'),
                items: const [
                  DropdownMenuItem(value: 'foot', child: Text('Piyoda')),
                  DropdownMenuItem(value: 'bicycle', child: Text('Velosiped')),
                  DropdownMenuItem(
                      value: 'motorcycle', child: Text('Mototsikl')),
                  DropdownMenuItem(value: 'car', child: Text('Avtomobil')),
                ],
                onChanged: (v) {
                  if (v != null) vehicleType.value = v;
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vehicleNumCtrl,
              decoration: const InputDecoration(
                labelText: 'Transport raqami',
                hintText: 'Masalan: 01 A 123 BC',
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: saving,
              builder: (context, isSaving, _) => FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        saving.value = true;
                        try {
                          final updated = await OrderService.updateProfile(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            vehicleType: vehicleType.value,
                            vehicleNumber: vehicleNumCtrl.text.trim(),
                          );
                          if (!context.mounted) return;
                          context.read<AuthProvider>().updateProfile(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil yangilandi')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          saving.value = false;
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    vehicleNumCtrl.dispose();
    vehicleType.dispose();
    saving.dispose();
  }

  /// Server manzili (API URL) sozlamasi.
  Future<void> _editServerAddress() async {
    final controller = TextEditingController(text: ApiClient.baseUrl);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Server manzili',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API manzilini kiriting (masalan: https://abc123.ngrok-free.app)',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (saved == null || !mounted) {
      controller.dispose();
      return;
    }

    final url = await ApiClient.setBaseUrl(saved);
    controller.dispose();
    if (url == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Noto\'g\'ri manzil. Qayta urinib ko\'ring.')),
      );
      return;
    }
    if (!context.mounted) return;
    setState(() {});
    try {
      await OrderService.getProfile();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server manzili saqlandi: $url')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manzil saqlandi, lekin serverga ulanib bo\'lmadi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<OrderProvider>();
    final stats = provider.stats;
    final earnings = provider.earnings;
    final name = auth.profile?.name ?? 'Kuryer';
    final phone = auth.profile?.phone ?? auth.profile?.email ?? '—';
    final online = auth.profile?.isOnline ?? false;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            name: name,
            onBellTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(height: 20),

          // ── Profil header ──
          Column(
            children: [
              // Gradient halqali avatar
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  boxShadow: kCardShadow,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Onlayn holat ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kCardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ishga chiqish holati',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          online ? 'Hozir onlayn' : 'Hozir oflayn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: online
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // iOS switch
                  _IOSSwitch(
                    value: online,
                    onChanged: _togglingOnline ? null : _toggleOnline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Avtomobil + shift ma'lumotlari ──
          if (auth.profile?.vehicleType.isNotEmpty == true ||
              auth.profile?.shiftStartedAt != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: kCardShadow,
                ),
                child: Column(
                  children: [
                    if (auth.profile?.vehicleType.isNotEmpty == true)
                      Row(
                        children: [
                          const Icon(Icons.directions_car_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_vehicleLabel(auth.profile!.vehicleType)}'
                              '${auth.profile!.vehicleNumber.isNotEmpty ? ' · ${auth.profile!.vehicleNumber}' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (auth.profile?.vehicleType.isNotEmpty == true &&
                        auth.profile?.shiftStartedAt != null)
                      const SizedBox(height: 10),
                    if (auth.profile?.shiftStartedAt != null)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Smena boshlandi: ${formatDateTime(auth.profile!.shiftStartedAt!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Stats grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.payments_outlined,
                  label: 'Bugungi daromad',
                  value: formatShort(earnings?.today ?? 0),
                  valueColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Umumiy daromad',
                  value: formatShort(earnings?.totalEarned ?? 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Bugungi zakazlar',
                  value: stats != null ? '${stats.todayDelivered}' : '—',
                  valueColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Jami zakazlar',
                  value: stats != null ? '${stats.totalDelivered}' : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Menyu ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kCardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.edit_outlined,
                    iconBg: AppColors.infoBg,
                    iconColor: AppColors.primary,
                    label: 'Profilni tahrirlash',
                    onTap: _editProfile,
                    showDivider: true,
                  ),
                  _MenuTile(
                    icon: Icons.support_agent,
                    iconBg: AppColors.primaryLight,
                    iconColor: AppColors.primaryDark,
                    label: 'Qo\'llab-quvvatlash',
                    onTap: _openSupport,
                    showDivider: true,
                  ),
                  _MenuTile(
                    icon: Icons.volume_up_outlined,
                    iconBg: AppColors.successBg,
                    iconColor: AppColors.success,
                    label: provider.soundOn ? 'Ovoz yoqilgan' : 'Ovoz o\'chirilgan',
                    onTap: () => context.read<OrderProvider>().toggleSound(),
                    showDivider: true,
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    iconBg: AppColors.surfaceContainerHigh,
                    iconColor: AppColors.textSecondary,
                    label: 'Sozlamalar',
                    onTap: _editServerAddress,
                    showDivider: true,
                  ),
                  _MenuTile(
                    icon: Icons.logout,
                    iconBg: AppColors.errorBg,
                    iconColor: AppColors.error,
                    label: 'Chiqish',
                    labelColor: AppColors.error,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Uvita Market · 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// iOS uslubidagi switch.
class _IOSSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _IOSSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 51,
        height: 31,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.success : const Color(0xFFE9E9EA),
          borderRadius: BorderRadius.circular(31),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.textMain,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 62,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
