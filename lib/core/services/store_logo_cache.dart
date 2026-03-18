import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'store_logo_cache.g.dart';

const _storeWebsitesKey = 'store_websites_cache';
const _knownStoreWebsites = <String, String>{
  'migros': 'https://www.migros.ch',
  'coop': 'https://www.coop.ch',
  'denner': 'https://www.denner.ch',
  'lidl': 'https://www.lidl.ch',
  'aldi': 'https://www.aldi.ch',
  'volg': 'https://www.volg.ch',
  'landi': 'https://www.landi.ch',
  'spar': 'https://www.spar.ch',
  'manor': 'https://www.manor.ch',
  'globus': 'https://www.globus.ch',
  'interdiscount': 'https://www.interdiscount.ch',
  'microspot': 'https://www.microspot.ch',
  'rewe': 'https://www.rewe.de',
  'edeka': 'https://www.edeka.de',
  'kaufland': 'https://www.kaufland.de',
  'dm': 'https://www.dm.de',
  'rossmann': 'https://www.rossmann.de',
  'mueller': 'https://www.mueller.de',
  'target': 'https://www.target.com',
  'walmart': 'https://www.walmart.com',
  'costco': 'https://www.costco.com',
  'whole foods': 'https://www.wholefoodsmarket.com',
  'trader joe\'s': 'https://www.traderjoes.com',
  'tesco': 'https://www.tesco.com',
  'sainsbury\'s': 'https://www.sainsburys.co.uk',
  'waitrose': 'https://www.waitrose.com',
  'asda': 'https://www.asda.com',
  'morrisons': 'https://www.morrisons.com',
  'aldi nord': 'https://www.aldi-nord.de',
  'aldi süd': 'https://www.aldi-sued.de',
  'carrefour': 'https://www.carrefour.com',
  'leclerc': 'https://www.e.leclerc',
  'auchan': 'https://www.auchan.fr',
};

@Riverpod(keepAlive: true)
StoreLogoCache storeLogoCache(StoreLogoCacheRef ref) {
  throw UnimplementedError('storeLogoCacheProvider must be overridden');
}

class StoreLogoCache {
  final SharedPreferences _prefs;
  Map<String, String>? _cache;

  StoreLogoCache(this._prefs);

  Future<void> _loadCache() async {
    if (_cache != null) return;
    try {
      final jsonString = _prefs.getString(_storeWebsitesKey);
      if (jsonString == null || jsonString.isEmpty) {
        _cache = {};
        return;
      }
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      _cache = decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint('StoreLogoCache: Failed to load cache: $e');
      _cache = {};
    }
  }

  Future<void> _saveCache() async {
    if (_cache == null) return;
    try {
      final jsonString = jsonEncode(_cache);
      await _prefs.setString(_storeWebsitesKey, jsonString);
    } catch (e) {
      debugPrint('StoreLogoCache: Failed to save cache: $e');
    }
  }

  String _normalizeStoreName(String storeName) {
    return storeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String normalizeWebsite(String input) {
    String website = input.trim();
    if (website.isEmpty) return '';

    // Remove protocol for normalization check
    String normalized = website.toLowerCase();
    if (normalized.startsWith('https://')) {
      normalized = normalized.substring(8);
    } else if (normalized.startsWith('http://')) {
      normalized = normalized.substring(7);
    }

    // Remove www prefix for checking
    if (normalized.startsWith('www.')) {
      normalized = normalized.substring(4);
    }

    // Remove trailing slash
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Rebuild with https:// prefix
    String result;
    if (website.toLowerCase().startsWith('http')) {
      // Keep existing protocol
      result = website.trim();
      if (result.endsWith('/')) {
        result = result.substring(0, result.length - 1);
      }
    } else {
      // Add https://
      result = 'https://www.$normalized';
    }

    return result;
  }

  Future<String?> getWebsite(String storeName) async {
    await _loadCache();
    final normalized = _normalizeStoreName(storeName);

    // First check user-defined cache
    if (_cache!.containsKey(normalized)) {
      return _cache![normalized];
    }

    // Then check known websites
    for (final entry in _knownStoreWebsites.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Try direct lookup with normalized name
    return _cache![normalized];
  }

  Future<void> setWebsite(String storeName, String website) async {
    if (website.trim().isEmpty) return;
    final normalizedWebsite = normalizeWebsite(website);
    if (normalizedWebsite.isEmpty) return;
    try {
      await _loadCache();
      final normalized = _normalizeStoreName(storeName);
      _cache![normalized] = normalizedWebsite;
      await _saveCache();
    } catch (e) {
      debugPrint('StoreLogoCache: Failed to save website: $e');
    }
  }

  Future<void> clearWebsite(String storeName) async {
    await _loadCache();
    final normalized = _normalizeStoreName(storeName);
    _cache!.remove(normalized);
    await _saveCache();
  }

  Future<void> clearAll() async {
    _cache = {};
    await _prefs.remove(_storeWebsitesKey);
  }

  Future<Map<String, String>> getAll() async {
    await _loadCache();
    return Map.unmodifiable(_cache!);
  }

  String extractDomain(String website) {
    String domain = website.trim();

    // Remove protocol
    if (domain.startsWith('https://')) {
      domain = domain.substring(8);
    } else if (domain.startsWith('http://')) {
      domain = domain.substring(7);
    }

    // Remove www.
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }

    // Remove path
    final slashIndex = domain.indexOf('/');
    if (slashIndex != -1) {
      domain = domain.substring(0, slashIndex);
    }

    return domain;
  }
}
