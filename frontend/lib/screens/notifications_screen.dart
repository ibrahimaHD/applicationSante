import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel user;
  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/rendez-vous/notifications'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _notifications = data['notifications'] ?? []);
        // Marquer comme lues
        await http.patch(
          Uri.parse('${AppConstants.baseUrl}/rendez-vous/notifications/lues'),
          headers: await _headers(),
        );
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'rdv': return const Color(0xFF00897B);
      case 'confirme': return AppColors.success;
      case 'annule':
      case 'annulation': return AppColors.error;
      case 'termine': return AppColors.textSecondary;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'rdv': return Icons.calendar_today_outlined;
      case 'confirme': return Icons.check_circle_outline;
      case 'annule':
      case 'annulation': return Icons.cancel_outlined;
      case 'termine': return Icons.done_all;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucune notification',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final type = n['type'] ?? 'info';
                      final color = _typeColor(type);
                      final lu = n['lu'] == true || n['lu'] == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lu ? Colors.white : color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: lu ? AppColors.divider : color.withOpacity(0.3),
                          ),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_typeIcon(type), color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(n['titre'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: lu ? FontWeight.w500 : FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ))),
                                if (!lu)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(n['message'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                (n['created_at'] ?? '').toString().length >= 16
                                    ? n['created_at'].toString().substring(0, 16)
                                    : '',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          )),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}