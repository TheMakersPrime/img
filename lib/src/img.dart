// Copyright (c) 2025 ThemMakersPrime Authors. All rights reserved.

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

enum _ImageSourceType { asset, network, memory }

class Img extends StatelessWidget {
  const Img.network({
    super.key,
    required String? url,
    this.height,
    this.width,
    this.color,
    this.inheritIconTheme = false,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.error,
    this.memCacheWidth,
    this.memCacheHeight,
    this.showBorderAroundPlaceholder = false,
    this.colorMode = BlendMode.srcIn,
  }) : source = url,
       _sourceType = _ImageSourceType.network,
       package = null;

  const Img.asset({
    super.key,
    required String asset,
    required this.package,
    this.height,
    this.width,
    this.color,
    this.inheritIconTheme = false,
    this.fit = BoxFit.contain,
    this.showBorderAroundPlaceholder = false,
    this.colorMode = BlendMode.srcIn,
    this.error,
  }) : source = asset,
       _sourceType = _ImageSourceType.asset,
       memCacheHeight = null,
       memCacheWidth = null,
       placeholder = null;

  const Img.memory({
    super.key,
    required String asset,
    this.height,
    this.width,
    this.color,
    this.inheritIconTheme = false,
    this.fit = BoxFit.contain,
    this.showBorderAroundPlaceholder = false,
    this.colorMode = BlendMode.srcIn,
    this.placeholder,
    this.error,
  }) : source = asset,
       _sourceType = _ImageSourceType.memory,
       package = null,
       memCacheHeight = null,
       memCacheWidth = null;

  final String? package;
  final String? source;
  final double? height;
  final double? width;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Color? color;
  final BoxFit fit;
  final bool inheritIconTheme;
  final bool showBorderAroundPlaceholder;
  final BlendMode colorMode;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? error;

  final _ImageSourceType _sourceType;

  @override
  Widget build(BuildContext context) {
    final _color = inheritIconTheme ? IconTheme.of(context).color : color;
    final isSvg = source?.contains('.svg') ?? false;

    switch (_sourceType) {
      case _ImageSourceType.asset:
        return isSvg
            ? SvgPicture(
                AssetBytesLoader(
                  source ?? '',
                  packageName: package,
                ),
                width: width,
                height: height,
                colorFilter: _color == null ? null : ColorFilter.mode(_color, colorMode),
                fit: fit,
              )
            : Image.asset(
                source ?? '',
                height: height,
                width: width,
                package: package,
                color: _color,
                fit: fit,
              );
      case _ImageSourceType.network:
        final errorWidget = error?.call(context) ?? _ErrorWidget(height);
        if (source == null) return errorWidget;

        if (isSvg) {
          return _CachedSvgNetworkImage(
            imageUrl: source!,
            height: height,
            width: width,
            fit: fit,
            color: _color,
            placeholder: (context) {
              final child = placeholder?.call(context);
              return child ?? errorWidget;
            },
          );
        }

        return CachedNetworkImage(
          imageUrl: source!,
          height: height,
          width: width,
          color: _color,
          fit: fit,
          memCacheWidth: memCacheWidth ?? 1024,
          memCacheHeight: memCacheHeight,
          placeholder: (context, _) => placeholder?.call(context) ?? errorWidget,
          errorWidget: (context, _, __) => error?.call(context) ?? errorWidget,
        );
      case _ImageSourceType.memory:
        if (source == null) {
          return error?.call(context) ?? _ErrorWidget(height);
        }

        return Image.memory(
          base64Decode(source!),
          height: height,
          width: width,
          color: _color,
          fit: fit,
        );
    }
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget(this.size);

  final double? size;

  @override
  Widget build(BuildContext context) {
    final baseSize = size ?? 32;
    // Since we need the ratio of baseSize with iconSize to be 3:2,
    final iconSize = baseSize * 2 / 3;

    final color = Theme.of(context).colorScheme;
    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.surfaceContainer,
          borderRadius: BorderRadius.circular(baseSize),
        ),
        child: Icon(size: iconSize, Icons.landscape, color: color.onSurfaceVariant),
      ),
    );
  }
}

class _CachedSvgNetworkImage extends StatefulWidget {
  const _CachedSvgNetworkImage({
    required this.imageUrl,
    required this.placeholder,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.color,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final WidgetBuilder placeholder;
  final BoxFit fit;
  final Color? color;

  @override
  State<_CachedSvgNetworkImage> createState() => _CachedSvgNetworkImageState();
}

class _CachedSvgNetworkImageState extends State<_CachedSvgNetworkImage> {
  late final String _cacheKey;
  late final DefaultCacheManager _cacheManager;
  late final Future<String> _image;

  @override
  void initState() {
    super.initState();
    _cacheManager = DefaultCacheManager();
    _cacheKey = widget.imageUrl;
    _image = _loadAndCacheImage();
  }

  Future<String> _loadAndCacheImage() async {
    final fileInfo = await _cacheManager.getFileFromMemory(_cacheKey);
    var file = fileInfo?.file;

    // `getSingleFile()` is responsible to get the file and cache it at the same time.
    return (file ??= await _cacheManager.getSingleFile(widget.imageUrl, key: _cacheKey)).readAsString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _image,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return widget.placeholder(context);
        return SvgPicture.string(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          colorFilter: widget.color == null
              ? null
              : ColorFilter.mode(
                  widget.color!,
                  BlendMode.srcIn,
                ),
          placeholderBuilder: widget.placeholder,
        );
      },
    );
  }
}
