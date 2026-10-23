import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/campo_arena.dart';
import '../models/pelada.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/profile_navigation_helper.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_sports_rail_menu.dart';
import '../widgets/app_drawer.dart';
import 'cadastro_pelada_screen.dart';
import 'campos_arenas_screen.dart';
import 'home_screen.dart';
import 'pelada_detail_screen.dart';
import 'campo_detail_screen.dart';
import 'login_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  static const LatLng _centroBrasil = LatLng(-14.2350, -51.9253);

  GoogleMapController? _mapController;
  LatLng? _localizacaoUsuario;
  bool _mostrarEventos = true;
  bool _mostrarCampos = true;
  MapType _mapType = MapType.normal;
  bool _carregando = true;
  String? _erroLocalizacao;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarMapa());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _carregarMapa() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erroLocalizacao = null;
    });

    final data = context.read<DataService>();
    final localizacaoFuture = _obterLocalizacaoUsuario();
    await Future.wait([
      data.carregarPeladas(),
      data.carregarCamposArenas(),
      localizacaoFuture,
    ]);

    if (!mounted) return;
    setState(() => _carregando = false);
    await _focarLocalizacaoInicial(data);
  }

  Future<void> _obterLocalizacaoUsuario() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _erroLocalizacao =
            'Ative a localização para destacar os mais próximos.';
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        _erroLocalizacao =
            'Permita o acesso à localização para centralizar o mapa.';
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _localizacaoUsuario = LatLng(posicao.latitude, posicao.longitude);
    } catch (_) {
      _erroLocalizacao = 'Não foi possível obter sua localização.';
    }
  }

  LatLng _centroInicial(DataService data) {
    if (_localizacaoUsuario != null) return _localizacaoUsuario!;
    final itens = <LatLng>[
      for (final pelada in data.peladas)
        if (_coordenadasValidas(pelada.latitude, pelada.longitude))
          LatLng(pelada.latitude!, pelada.longitude!),
      for (final campo in data.camposArenas)
        if (_coordenadasValidas(campo.latitude, campo.longitude))
          LatLng(campo.latitude!, campo.longitude!),
    ];
    if (itens.isEmpty) return _centroBrasil;
    return itens.first;
  }

  Future<void> _focarLocalizacaoInicial(DataService data) async {
    if (!mounted) return;
    final destino = _centroInicial(data);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        destino,
        _localizacaoUsuario == null ? (destino == _centroBrasil ? 4 : 12) : 13,
      ),
    );
  }

  static bool _coordenadasValidas(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }

  Set<Marker> _criarMarcadores(DataService data) {
    final markers = <Marker>{};
    if (_mostrarEventos) {
      for (final pelada in data.peladas) {
        if (!_coordenadasValidas(pelada.latitude, pelada.longitude)) continue;
        markers.add(_marcadorPelada(pelada));
      }
    }
    if (_mostrarCampos) {
      for (final campo in data.camposArenas) {
        if (!_coordenadasValidas(campo.latitude, campo.longitude)) continue;
        markers.add(_marcadorCampo(campo));
      }
    }
    if (_localizacaoUsuario case final posicao?) {
      markers.add(
        Marker(
          markerId: const MarkerId('localizacao-usuario'),
          position: posicao,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Sua localização'),
          zIndexInt: 2,
        ),
      );
    }
    return markers;
  }

  Marker _marcadorPelada(Pelada pelada) {
    return Marker(
      markerId: MarkerId('evento-${pelada.id}'),
      position: LatLng(pelada.latitude!, pelada.longitude!),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
        title: pelada.nome,
        snippet: '${pelada.cidade} - ${pelada.estado}',
      ),
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PeladaDetailScreen(peladaId: pelada.id),
          ),
        );
      },
    );
  }

  Marker _marcadorCampo(CampoArena campo) {
    return Marker(
      markerId: MarkerId('campo-${campo.id}'),
      position: LatLng(campo.latitude!, campo.longitude!),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: campo.nome,
        snippet: '${campo.cidade} - ${campo.estado}',
      ),
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CampoDetailScreen(campo: campo)),
        );
      },
    );
  }

  void _navegarBarraInferior(BuildContext context, int indice) {
    unawaited(HapticFeedback.selectionClick());
    final navigator = Navigator.of(context);
    switch (indice) {
      case 0:
        if (!context.read<AuthService>().isAuthenticated) {
          navigator.push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          navigator.push(
            MaterialPageRoute(builder: (_) => const CadastroPeladaScreen()),
          );
        }
        return;
      case 1:
        navigator.push(
          MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 1)),
        );
        return;
      case 2:
        navigator.push(
          MaterialPageRoute(builder: (_) => const CamposArenasScreen()),
        );
        return;
      case 3:
        unawaited(navigateToProfile(context));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Mapa'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _mostrarEventos ? 'Ocultar eventos' : 'Exibir eventos',
            onPressed: () => setState(() => _mostrarEventos = !_mostrarEventos),
            style: IconButton.styleFrom(
              backgroundColor: _mostrarEventos
                  ? Colors.amber.withValues(alpha: 0.20)
                  : Colors.transparent,
              foregroundColor: _mostrarEventos
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.sports_soccer_outlined),
          ),
          IconButton(
            tooltip: _mostrarCampos
                ? 'Ocultar campos e arenas'
                : 'Exibir campos e arenas',
            onPressed: () => setState(() => _mostrarCampos = !_mostrarCampos),
            style: IconButton.styleFrom(
              backgroundColor: _mostrarCampos
                  ? Colors.green.withValues(alpha: 0.16)
                  : Colors.transparent,
              foregroundColor: _mostrarCampos
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.stadium_outlined),
          ),
        ],
      ),
      body: Consumer<DataService>(
        builder: (context, data, _) => Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              mapType: _mapType,
              initialCameraPosition: CameraPosition(
                target: _centroInicial(data),
                zoom: _localizacaoUsuario == null
                    ? (_centroInicial(data) == _centroBrasil ? 4 : 12)
                    : 13,
              ),
              markers: _criarMarcadores(data),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                unawaited(_focarLocalizacaoInicial(data));
              },
            ),
            if (_carregando)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.surface,
                child: IconButton(
                  tooltip: _mapType == MapType.normal
                      ? 'Mudar para satélite'
                      : 'Mudar para mapa',
                  onPressed: () => setState(
                    () => _mapType = _mapType == MapType.normal
                        ? MapType.satellite
                        : MapType.normal,
                  ),
                  icon: Icon(
                    Icons.layers_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (_erroLocalizacao != null && !_carregando)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_searching,
                          color: theme.colorScheme.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _erroLocalizacao!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          Widget? centerMenu;
          if (auth.isAuthenticated) {
            centerMenu = ProfileSportsRailMenu(
              buttonDiameter: CustomBottomNavBar.fabDiameter,
              verticalSpacing: 6,
              labelColumnWidth: 92,
              labelGutter: 10,
              labelOffsetAdjust: const EdgeInsets.only(right: 6),
              notchDockedOffset: 0,
              activeButtonId: 'mapa',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: -1,
            tipoFavoritoBadge: TipoFavoritoBadge.peladas,
            customCenterMenu: centerMenu ?? const SizedBox.shrink(),
            showCenterHomeButton: !auth.isAuthenticated,
            onTabSelected: (indice) =>
                _navegarBarraInferior(context, indice),
          );
        },
      ),
    );
  }
}
