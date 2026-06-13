import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';

class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key});
  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  static const LatLng _storeLocation = LatLng(10.7769, 106.7009);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cửa hàng NURA')),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=rmh6lqFUkYtkdDScBa7j',
                userAgentPackageName: 'com.fpt.mombabymilk',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28, minChildSize: 0.12, maxChildSize: 0.45,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('NURA Baby & Mom Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined, '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh'),
                  _infoRow(Icons.phone_outlined, '028 1234 5678'),
                  _infoRow(Icons.access_time, '8:00 - 21:00 (Thứ 2 - Chủ nhật)'),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=10.7769,106.7009')),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:02812345678')),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Gọi điện'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
      ]),
    );
  }
}
