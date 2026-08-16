import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../services/trip_service.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CourierTrip? _trip;
  List<TripRoute> _routes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final active = await TripService.active();
      final routes =
          active == null ? await TripService.routes() : <TripRoute>[];
      if (!mounted) return;
      setState(() {
        _trip = active;
        _routes = routes;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppTopBar(
              name: profile?.name,
              onBellTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              )),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_loading) const _LoadingCard(),
                if (_error != null)
                  _ErrorCard(message: _error!, retry: _refresh),
                if (!_loading && _error == null && _trip == null)
                  _RoutesView(
                    routes: _routes,
                    capacityKg: profile?.vehicleCapacityKg ?? 1000,
                    onCreated: (trip) => setState(() => _trip = trip),
                  ),
                if (!_loading && _trip != null)
                  _ActiveTripView(
                    trip: _trip!,
                    onChanged: (trip) => setState(() => _trip = trip),
                    onFinished: _refresh,
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutesView extends StatelessWidget {
  final List<TripRoute> routes;
  final double capacityKg;
  final ValueChanged<CourierTrip> onCreated;
  const _RoutesView({
    required this.routes,
    required this.capacityKg,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const _InfoCard(
        icon: Icons.route_outlined,
        title: 'Hozircha reys yo‘q',
        text: 'Tayyor yuklar paydo bo‘lganda yo‘nalishlar shu yerda chiqadi.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reysni tanlang',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'Zakazlarni tizim sig‘im, masofa va navbat bo‘yicha o‘zi tanlaydi.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 18),
        for (final route in routes) ...[
          _RouteCard(
            route: route,
            onTap: () async {
              final trip = await showModalBottomSheet<CourierTrip>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    _PlanSheet(route: route, capacityKg: capacityKg),
              );
              if (trip != null) onCreated(trip);
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final TripRoute route;
  final VoidCallback onTap;
  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kCardRadius),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: .45)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.trip_origin,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${route.origin} → ${route.destination}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Chip('${route.ordersCount} ta zakaz',
                    Icons.inventory_2_outlined),
                _Chip('${route.pickupPointsCount} ta pickup',
                    Icons.storefront_outlined),
                _Chip('${_kg(route.totalWeightKg)} kg', Icons.scale_outlined),
              ]),
              const SizedBox(height: 14),
              Text('Kutiladigan haq: ${formatMoney(route.totalCourierFee)}',
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class _PlanSheet extends StatefulWidget {
  final TripRoute route;
  final double capacityKg;
  const _PlanSheet({required this.route, required this.capacityKg});

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  TripPreview? preview;
  bool loading = true;
  bool creating = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await TripService.preview(widget.route.key,
          capacityKg: widget.capacityKg);
      if (mounted) setState(() => preview = value);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    setState(() => creating = true);
    try {
      final trip = await TripService.create(widget.route.key,
          capacityKg: widget.capacityKg);
      if (mounted) Navigator.pop(context, trip);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Text('${widget.route.origin} → ${widget.route.destination}',
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Profil sig‘imi: ${_kg(widget.capacityKg)} kg · Yuk qiymati 50 mln so‘mdan oshmaydi',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: AppColors.error)),
            if (preview != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  _SummaryRow(
                      'Avtomatik tanlandi', '${preview!.ordersCount} ta zakaz'),
                  _SummaryRow(
                      'Yuk olish joyi', '${preview!.pickupPointsCount} ta'),
                  _SummaryRow(
                      'Umumiy og‘irlik', '${_kg(preview!.totalWeightKg)} kg'),
                  _SummaryRow(
                      'Naqd yuk qiymati', formatMoney(preview!.cargoValue)),
                  _SummaryRow(
                      'Sizning haqingiz', formatMoney(preview!.courierFee),
                      positive: true),
                ]),
              ),
              const SizedBox(height: 18),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: creating ? null : _create,
                    child: Text(creating
                        ? 'Shakllantirilmoqda…'
                        : 'Zakazlarni avtomatik olish'),
                  )),
            ],
          ]),
        ),
      );
}

class _ActiveTripView extends StatelessWidget {
  final CourierTrip trip;
  final ValueChanged<CourierTrip> onChanged;
  final VoidCallback onFinished;
  const _ActiveTripView(
      {required this.trip, required this.onChanged, required this.onFinished});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TripHeader(trip: trip),
          const SizedBox(height: 18),
          if (trip.pickingUp)
            _PickupList(
              trip: trip,
              onChanged: onChanged,
              onCancelled: onFinished,
            )
          else if (!trip.completed)
            _DeliveryList(trip: trip, onChanged: onChanged)
          else
            _CompletedTrip(trip: trip, onFinished: onFinished),
        ],
      );
}

class _TripHeader extends StatelessWidget {
  final CourierTrip trip;
  const _TripHeader({required this.trip});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF075CCB), AppColors.primary]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              trip.pickingUp
                  ? 'Yuklarni olish'
                  : trip.completed
                      ? 'Reys yakunlandi'
                      : 'Yetkazib berish',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${trip.origin} → ${trip.destination}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(
              '${trip.ordersCount} ta zakaz · ${_kg(trip.totalWeightKg)} kg · ${formatMoney(trip.totalCourierFee)} haq',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _PickupList extends StatefulWidget {
  final CourierTrip trip;
  final ValueChanged<CourierTrip> onChanged;
  final VoidCallback onCancelled;
  const _PickupList({
    required this.trip,
    required this.onChanged,
    required this.onCancelled,
  });
  @override
  State<_PickupList> createState() => _PickupListState();
}

class _PickupListState extends State<_PickupList> {
  String? busy;
  @override
  Widget build(BuildContext context) {
    final left = widget.trip.pickups.where((p) => !p.pickedUp).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Yuk olish ketma-ketligi · $left ta qoldi',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Xaridor manzillari barcha yuklar olingach ochiladi.',
          style: TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 14),
      for (final pickup in widget.trip.pickups) ...[
        _StopCard(
          number: pickup.sequence,
          done: pickup.pickedUp,
          title: pickup.businessName,
          subtitle: [pickup.region, pickup.district, pickup.address]
              .where((e) => e.isNotEmpty)
              .join(', '),
          detail: '${pickup.ordersCount} ta zakaz · ${_kg(pickup.weightKg)} kg',
          location: pickup.location,
          actionLabel: 'Yukni oldim',
          busy: busy == pickup.key,
          onAction: pickup.pickedUp ? null : () => _pickup(pickup),
        ),
        const SizedBox(height: 12),
      ],
      if (widget.trip.pickups.every((p) => !p.pickedUp)) ...[
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _cancel,
            child: const Text('Reysdan voz kechish'),
          ),
        ),
      ],
    ]);
  }

  Future<void> _cancel() async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reysdan voz kechish'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Faqat 5 soat ichida va birorta yuk olinmagan bo‘lsa mumkin.'),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Sabab'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Qolish')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Voz kechish')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await TripService.cancel(widget.trip.id, reason.text.trim());
      if (mounted) widget.onCancelled();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _pickup(PickupPoint point) async {
    setState(() => busy = point.key);
    try {
      final before = widget.trip.status;
      final trip = await TripService.pickup(widget.trip.id, point.key);
      if (!mounted) return;
      widget.onChanged(trip);
      if (before == 'picking_up' && trip.status == 'delivering') {
        await _showCelebration(context, 'Barcha yuklar olindi!',
            'Endi xaridor manzillari ochildi. Yetkazishni boshlang.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }
}

class _DeliveryList extends StatefulWidget {
  final CourierTrip trip;
  final ValueChanged<CourierTrip> onChanged;
  const _DeliveryList({required this.trip, required this.onChanged});
  @override
  State<_DeliveryList> createState() => _DeliveryListState();
}

class _DeliveryListState extends State<_DeliveryList> {
  int? busy;
  @override
  Widget build(BuildContext context) {
    final left = widget.trip.deliveries.where((d) => !d.delivered).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Yetkazish ketma-ketligi · $left ta qoldi',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      for (final delivery in widget.trip.deliveries) ...[
        _StopCard(
          number: delivery.sequence,
          done: delivery.delivered,
          title: 'Zakaz #${delivery.orderId}',
          subtitle: _address(delivery.address),
          detail:
              'Naqd: ${formatMoney(delivery.cashDue)} · ${delivery.deliveryScope == 'city' ? 'shahar ichida' : 'tuman markazida'}',
          location: delivery.location,
          actionLabel: 'Yetkazishni yakunlash',
          busy: busy == delivery.orderId,
          onAction: delivery.delivered ? null : () => _deliver(delivery),
        ),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Future<void> _deliver(TripDelivery delivery) async {
    final pin = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Zakaz #${delivery.orderId}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Mijozdan quyidagi naqd summani oling:'),
          const SizedBox(height: 10),
          Text(formatMoney(delivery.cashDue),
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success)),
          const SizedBox(height: 16),
          TextField(
            controller: pin,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
                labelText: 'Mijozning 4 xonali PIN kodi', counterText: ''),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tasdiqlash')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!RegExp(r'^\d{4}$').hasMatch(pin.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('4 xonali PIN kiriting')));
      }
      return;
    }
    setState(() => busy = delivery.orderId);
    try {
      final trip = await TripService.deliver(
        tripId: widget.trip.id,
        orderId: delivery.orderId,
        pin: pin.text,
        cashReceived: delivery.cashDue,
      );
      if (!mounted) return;
      widget.onChanged(trip);
      if (trip.completed) {
        await _showCelebration(context, 'Hamma zakazlar yetkazildi!',
            'Reys muvaffaqiyatli yakunlandi. Moliyaviy hisob tayyor.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }
}

class _StopCard extends StatelessWidget {
  final int number;
  final bool done;
  final String title;
  final String subtitle;
  final String detail;
  final TripLocation? location;
  final String actionLabel;
  final bool busy;
  final VoidCallback? onAction;
  const _StopCard(
      {required this.number,
      required this.done,
      required this.title,
      required this.subtitle,
      required this.detail,
      required this.location,
      required this.actionLabel,
      required this.busy,
      required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: done ? AppColors.successBg : AppColors.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(
              color: done
                  ? AppColors.success.withValues(alpha: .35)
                  : AppColors.outlineVariant.withValues(alpha: .45)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              child: done
                  ? const Icon(Icons.check, size: 20)
                  : Text('$number',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.35))
                  ],
                  const SizedBox(height: 7),
                  Text(detail,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ])),
          ]),
          if (!done) ...[
            const SizedBox(height: 14),
            Row(children: [
              if (location != null) ...[
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: () => _openNavigator(location!),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigator'),
                )),
                const SizedBox(width: 10),
              ],
              Expanded(
                  child: FilledButton(
                onPressed: busy ? null : onAction,
                child: Text(busy ? 'Kutilmoqda…' : actionLabel,
                    textAlign: TextAlign.center),
              )),
            ]),
          ],
        ]),
      );
}

class _CompletedTrip extends StatelessWidget {
  final CourierTrip trip;
  final VoidCallback onFinished;
  const _CompletedTrip({required this.trip, required this.onFinished});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: kCardShadow),
        child: Column(children: [
          const Icon(Icons.verified_rounded,
              color: AppColors.success, size: 56),
          const SizedBox(height: 12),
          const Text('Moliyaviy yakun',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          _SummaryRow('Mijozlardan olindi', formatMoney(trip.cashCollected)),
          _SummaryRow('Sizning haqingiz', formatMoney(trip.totalCourierFee),
              positive: true),
          _SummaryRow('Platformaga topshiriladi',
              formatMoney(trip.platformCashDue ?? 0)),
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: onFinished,
                  child: const Text('Yangi reyslarni ko‘rish'))),
        ]),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;
  const _SummaryRow(this.label, this.value, {this.positive = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: positive ? AppColors.success : AppColors.textMain)),
        ]),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip(this.text, this.icon);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))
        ]),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator()));
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorCard({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => _InfoCard(
      icon: Icons.error_outline,
      title: 'Ma’lumot yuklanmadi',
      text: message,
      action: retry);
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? action;
  const _InfoCard(
      {required this.icon,
      required this.title,
      required this.text,
      this.action});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: action, child: const Text('Qayta urinish'))
          ],
        ]),
      );
}

Future<void> _openNavigator(TripLocation location) async {
  final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _showCelebration(
        BuildContext context, String title, String text) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉 ✨ 🎊', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Davom etish'))),
        ]),
      ),
    );

String _address(Map<String, dynamic> a) => [
      a['region'],
      a['district'],
      a['delivery_point'],
      a['street'],
      a['house']
    ].where((e) => e != null && '$e'.trim().isNotEmpty).join(', ');

String _kg(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
