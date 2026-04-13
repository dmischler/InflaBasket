import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/services/store_logo_cache.dart';

class StoreLogoWidget extends ConsumerStatefulWidget {
  final String storeName;
  final String fallbackLetter;
  final String? website;
  final double radius;

  const StoreLogoWidget({
    super.key,
    required this.storeName,
    required this.fallbackLetter,
    this.website,
    this.radius = 20,
  });

  @override
  ConsumerState<StoreLogoWidget> createState() => _StoreLogoWidgetState();
}

class _StoreLogoWidgetState extends ConsumerState<StoreLogoWidget> {
  String? _resolvedWebsite;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _resolveWebsite();
  }

  @override
  void didUpdateWidget(StoreLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeName != widget.storeName ||
        oldWidget.website != widget.website) {
      _loadFailed = false;
      _resolveWebsite();
    }
  }

  Future<void> _resolveWebsite() async {
    if (widget.website != null && widget.website!.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _resolvedWebsite = widget.website;
        _isLoading = false;
      });
      return;
    }

    final cache = ref.read(storeLogoCacheProvider);
    final website = await cache.getWebsite(widget.storeName);
    if (!mounted) return;
    setState(() {
      _resolvedWebsite = website;
      _isLoading = false;
    });
  }

  String? _getLogoUrl(String website) {
    if (website.isEmpty) return null;

    final cache = ref.read(storeLogoCacheProvider);
    final domain = cache.extractDomain(website);

    if (domain.isEmpty) return null;

    // DuckDuckGo favicon API (primary)
    return 'https://icons.duckduckgo.com/ip3/$domain.ico';
  }

  String? _getFallbackLogoUrl(String website) {
    if (website.isEmpty) return null;

    final cache = ref.read(storeLogoCacheProvider);
    final domain = cache.extractDomain(website);

    if (domain.isEmpty) return null;

    // Vemetric favicon API (fallback)
    return 'https://favicon.vemetric.com/$domain?size=${(widget.radius * 2).round()}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLetterAvatar();
    }

    final website = _resolvedWebsite;
    if (website == null || website.isEmpty) {
      return _buildLetterAvatar();
    }

    final logoUrl = _getLogoUrl(website);
    final fallbackUrl = _getFallbackLogoUrl(website);

    if (logoUrl == null) {
      return _buildLetterAvatar();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
      child: ClipOval(
        child: _loadFailed && fallbackUrl != null
            ? CachedNetworkImage(
                imageUrl: fallbackUrl,
                width: widget.radius * 2,
                height: widget.radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildLetterAvatar(),
                errorWidget: (_, __, ___) => _buildLetterAvatar(),
              )
            : CachedNetworkImage(
                imageUrl: logoUrl,
                width: widget.radius * 2,
                height: widget.radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildLetterAvatar(),
                errorWidget: (_, __, ___) {
                  if (!_loadFailed && fallbackUrl != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _loadFailed = true;
                      });
                    });
                  }
                  return _buildLetterAvatar();
                },
              ),
      ),
    );
  }

  Widget _buildLetterAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
      child: Text(
        widget.fallbackLetter.isNotEmpty
            ? widget.fallbackLetter[0].toUpperCase()
            : '?',
        style: TextStyle(fontSize: widget.radius * 0.8),
      ),
    );
  }
}
