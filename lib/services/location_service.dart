import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CepResultado {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final bool sucesso;

  const CepResultado({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.sucesso,
  });
}

class Coordenadas {
  final double latitude;
  final double longitude;
  const Coordenadas(this.latitude, this.longitude);
}

class LocationService {
  static const _viaCepBase = 'https://viacep.com.br/ws';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static final Map<String, List<String>> _municipiosPorUf = {};

  static Future<List<String>> buscarMunicipiosPorUf(String uf) async {
    final sigla = uf.trim().toUpperCase();
    if (sigla.isEmpty) return const [];
    final cached = _municipiosPorUf[sigla];
    if (cached != null) return cached;

    final uri = Uri.https(
      'servicodados.ibge.gov.br',
      '/api/v1/localidades/estados/$sigla/municipios',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar as cidades deste estado.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Resposta inválida ao buscar municípios.');
    }
    final municipios =
        decoded
            .whereType<Map<String, dynamic>>()
            .map((municipio) => municipio['nome'])
            .whereType<String>()
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _municipiosPorUf[sigla] = municipios;
    return municipios;
  }

  static String apenasDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  static bool formatoCepValido(String? entrada) {
    final digitos = apenasDigitos(entrada ?? '');
    return digitos.length == 8 && RegExp(r'^\d{8}$').hasMatch(digitos);
  }

  static Future<CepResultado> consultarCep(String? entrada) async {
    final digitos = apenasDigitos(entrada ?? '');
    if (digitos.length != 8) {
      return const CepResultado(
        cep: '',
        logradouro: '',
        complemento: '',
        bairro: '',
        cidade: '',
        uf: '',
        sucesso: false,
      );
    }
    try {
      final uri = Uri.parse('$_viaCepBase/$digitos/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return const CepResultado(
          cep: '',
          logradouro: '',
          complemento: '',
          bairro: '',
          cidade: '',
          uf: '',
          sucesso: false,
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      if (kDebugMode) {
        debugPrint('[LocationService] viacep response: $decoded');
      }
      if (decoded is! Map<String, dynamic>) {
        return const CepResultado(
          cep: '',
          logradouro: '',
          complemento: '',
          bairro: '',
          cidade: '',
          uf: '',
          sucesso: false,
        );
      }
      if (decoded['erro'] == true || decoded.containsKey('erro')) {
        return CepResultado(
          cep: decoded['cep'] as String? ?? digitos,
          logradouro: '',
          complemento: '',
          bairro: '',
          cidade: '',
          uf: '',
          sucesso: false,
        );
      }
      final rua = (decoded['logradouro'] as String?) ?? '';
      final localidade = (decoded['localidade'] as String?) ?? '';
      if (rua.isEmpty && localidade.isEmpty) {
        return CepResultado(
          cep: decoded['cep'] as String? ?? digitos,
          logradouro: '',
          complemento: '',
          bairro: '',
          cidade: '',
          uf: '',
          sucesso: false,
        );
      }
      return CepResultado(
        cep: decoded['cep'] as String? ?? digitos,
        logradouro: rua,
        complemento: (decoded['complemento'] as String?) ?? '',
        bairro: (decoded['bairro'] as String?) ?? '',
        cidade: localidade,
        uf: (decoded['uf'] as String?) ?? '',
        sucesso: true,
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationService] consultarCep erro: $e');
    }
    return const CepResultado(
      cep: '',
      logradouro: '',
      complemento: '',
      bairro: '',
      cidade: '',
      uf: '',
      sucesso: false,
    );
  }

  static ({String rua, String numero}) extrairNumeroDoEndereco(
    String endereco,
  ) {
    final String ruaTrim = endereco.trim();
    if (ruaTrim.isEmpty) return (rua: '', numero: '');
    final numMatch = RegExp(
      r'(?:[,，]\s*|\s+)(?:n[oº°]?\.?\s*)?(\d{1,8}(?:[\s\-]*[A-Za-z])?)[^\s,，]*$',
      caseSensitive: false,
    ).firstMatch(ruaTrim);
    if (numMatch != null) {
      final matchFull = numMatch.group(0)?.trim() ?? '';
      final matchNum = numMatch.group(1)?.trim() ?? '';
      if (matchNum.isNotEmpty && matchFull.isNotEmpty) {
        final startIdx = ruaTrim.lastIndexOf(matchFull);
        final cleanRua = (startIdx > 0)
            ? ruaTrim.substring(0, startIdx).trim()
            : ruaTrim.substring(0, ruaTrim.length - matchFull.length).trim();
        if (cleanRua.isNotEmpty) return (rua: cleanRua, numero: matchNum);
      }
    }
    return (rua: ruaTrim, numero: '');
  }

  static Future<Coordenadas?> geocodificarEndereco({
    required String endereco,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String localArena,
    String? cep,
  }) async {
    final digitosCep = apenasDigitos(cep?.trim() ?? '');
    final enderecoExtraido = extrairNumeroDoEndereco(endereco.trim());
    String ruaFinal = enderecoExtraido.rua;
    String numeroFinal = numero.trim().isNotEmpty
        ? numero.trim()
        : enderecoExtraido.numero;

    String montarQuery({
      required bool incluirBairro,
      required bool incluirArena,
      required bool incluirNumero,
      required bool incluirRua,
    }) {
      final partes = <String>[];
      if (incluirRua && ruaFinal.isNotEmpty) {
        if (incluirNumero && numeroFinal.isNotEmpty) {
          partes.add('$ruaFinal, $numeroFinal');
        } else {
          partes.add(ruaFinal);
        }
      } else if (incluirNumero && numeroFinal.isNotEmpty) {
        partes.add(numeroFinal);
      }
      if (incluirBairro && bairro.trim().isNotEmpty) partes.add(bairro.trim());
      if (incluirArena && localArena.trim().isNotEmpty) {
        partes.add(localArena.trim());
      }
      final cidadeUf = [
        if (cidade.trim().isNotEmpty) cidade.trim(),
        if (estado.trim().isNotEmpty) estado.trim(),
      ].join(' - ');
      if (cidadeUf.isNotEmpty) partes.add(cidadeUf);
      partes.add('Brasil');
      return partes.join(', ');
    }

    final qCompleta = montarQuery(
      incluirBairro: true,
      incluirArena: true,
      incluirNumero: true,
      incluirRua: true,
    );
    final qSemArena = montarQuery(
      incluirBairro: true,
      incluirArena: false,
      incluirNumero: true,
      incluirRua: true,
    );
    final qBasica = montarQuery(
      incluirBairro: false,
      incluirArena: false,
      incluirNumero: true,
      incluirRua: true,
    );
    final qCidadeEstado = montarQuery(
      incluirBairro: false,
      incluirArena: false,
      incluirNumero: false,
      incluirRua: false,
    );

    final candidatas = <String>[];
    if (qCompleta.replaceAll('Brasil', '').trim().isNotEmpty) {
      candidatas.add(qCompleta);
    }
    if (qSemArena != qCompleta &&
        qSemArena.replaceAll('Brasil', '').trim().isNotEmpty) {
      candidatas.add(qSemArena);
    }
    if (qBasica != qSemArena &&
        qBasica.replaceAll('Brasil', '').trim().isNotEmpty) {
      candidatas.add(qBasica);
    }
    if (qCidadeEstado.replaceAll('Brasil', '').trim().isNotEmpty) {
      candidatas.add(qCidadeEstado);
    }
    if (digitosCep.length == 8) {
      final uf = estado.trim().isNotEmpty ? ' ${estado.trim()}' : '';
      candidatas.add('CEP $digitosCep$uf, Brasil');
    }

    if (candidatas.isEmpty) return null;

    Future<Coordenadas?> buscarNominatim(String q) async {
      try {
        final uri = Uri.parse('$_nominatimBase/search').replace(
          queryParameters: {
            'q': q,
            'format': 'jsonv2',
            'limit': '1',
            'addressdetails': '0',
            'countrycodes': 'br',
          },
        );
        final res = await http
            .get(uri, headers: {'User-Agent': 'PeladeirosSA/1.0'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) return null;
        final list = jsonDecode(res.body);
        if (list is! List || list.isEmpty) return null;
        final first = list.first as Map<String, dynamic>;
        final lat = double.tryParse(first['lat'].toString());
        final lon = double.tryParse(first['lon'].toString());
        if (lat == null || lon == null) return null;
        return Coordenadas(lat, lon);
      } on TimeoutException {
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LocationService] nominatim erro (query="$q"): $e');
        }
        return null;
      }
    }

    try {
      for (final q in candidatas) {
        final r = await buscarNominatim(q);
        if (r != null) return r;
      }
      if (digitosCep.length == 8) {
        try {
          final via = await consultarCep(
            digitosCep,
          ).timeout(const Duration(seconds: 8));
          if (via.sucesso) {
            final viaCidade = via.cidade.trim().isNotEmpty
                ? via.cidade.trim()
                : cidade.trim();
            final viaUf = via.uf.trim().isNotEmpty
                ? via.uf.trim()
                : estado.trim();
            final viaRua = via.logradouro.trim().isNotEmpty
                ? via.logradouro.trim()
                : ruaFinal;
            final viaBairro = via.bairro.trim().isNotEmpty
                ? via.bairro.trim()
                : bairro.trim();
            if (viaCidade.isNotEmpty || viaRua.isNotEmpty) {
              final ps = <String>[
                if (viaRua.isNotEmpty)
                  (numeroFinal.isNotEmpty ? '$viaRua, $numeroFinal' : viaRua),
                if (viaBairro.isNotEmpty) viaBairro,
                [
                  if (viaCidade.isNotEmpty) viaCidade,
                  if (viaUf.isNotEmpty) viaUf,
                ].where((e) => e.isNotEmpty).join(' - '),
                'Brasil',
              ];
              final qVia = ps.join(', ');
              return await buscarNominatim(qVia);
            }
          }
        } catch (_) {
          // ignora
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] geocodificar erro: $e');
      }
      return null;
    }
  }

  static Future<bool> abrirGoogleMaps(Coordenadas? coords) async {
    if (coords == null) return false;
    final query = Uri.encodeComponent('${coords.latitude},${coords.longitude}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      final fallback = Uri.parse(
        'geo:${coords.latitude},${coords.longitude}?q=${coords.latitude},${coords.longitude}',
      );
      if (await canLaunchUrl(fallback)) {
        return await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationService] abrirMaps erro: $e');
      return false;
    }
  }

  static Future<Object?> buscarCep(String digitos) async {
    return null;
  }
}
