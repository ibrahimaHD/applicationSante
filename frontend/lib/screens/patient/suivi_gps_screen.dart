import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../constants/app_constants.dart';

class SuiviGpsScreen extends StatefulWidget {
  final int commandeId;
  const SuiviGpsScreen({super.key, required this.commandeId});

  @override
  State<SuiviGpsScreen> createState() => _SuiviGpsScreenState();
}

class _SuiviGpsScreenState extends State<SuiviGpsScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _position;
  Timer? _timer;
  io.Socket? _socket;
  bool _isLoading = true;
  bool _tempsReel = false;

  @override
  void initState() {
    super.initState();
    _connecterSocket();
    _charger();
    // Rafraîchir toutes les 10 secondes
    _timer = Timer.periodic(
        const Duration(seconds: 10), (_) => _charger());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket?.emit('arreter_suivi_commande', widget.commandeId);
    _socket?.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    final base = AppConstants.baseUrl.replaceFirst('/api', '');
    _socket = io.io(
      base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket?.connect();
    _socket?.onConnect((_) {
      _tempsReel = true;
      _socket?.emit('suivre_commande', widget.commandeId);
    });
    _socket?.onDisconnect((_) => _tempsReel = false);
    _socket?.on('position_livreur', (data) {
      if (!mounted || data == null) return;
      setState(() {
        _position = Map<String, dynamic>.from(data);
        _isLoading = false;
      });
      _deplacerCarte();
    });
  }

  void _deplacerCarte() {
    if (_position == null) return;
    _mapController.move(
      LatLng(
        double.parse(_position!['latitude'].toString()),
        double.parse(_position!['longitude'].toString()),
      ),
      15,
    );
  }

  Future<void> _charger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final response = await http.get(
        Uri.parse(
            '${AppConstants.baseUrl}/livraison/position/${widget.commandeId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _position  = data['position'];
            _isLoading = false;
          });
          _deplacerCarte();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = _position != null
        ? double.tryParse(_position!['latitude'].toString()) ?? 11.1771
        : 11.1771;
    final lng = _position != null
        ? double.tryParse(_position!['longitude'].toString()) ?? -4.2979
        : -4.2979;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4511E),
        title: Text('Suivi commande #${widget.commandeId}',
            style: const TextStyle(
                color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _charger,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _position == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Le livreur n\'est pas encore en route',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : Stack(children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.laafiba.health',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 50, height: 50,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4511E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 28),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  // Info livreur
                  Positioned(
                    bottom: 20, left: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4511E)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.delivery_dining_outlined,
                              color: Color(0xFFF4511E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_position!['livreur_prenom'] ?? ''} ${_position!['livreur_nom'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _position!['livreur_tel'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        )),
                        const Icon(Icons.circle,
                            color: AppColors.success, size: 10),
                        const SizedBox(width: 4),
                        Text(_tempsReel ? 'Temps réel' : 'En route',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success)),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}
