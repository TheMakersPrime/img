// Copyright (c) 2025 <org_name> Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum _SourceType { asset, network }

class Animg extends StatelessWidget {
  const Animg.network({
    super.key,
    required String url,
    this.height,
    this.width,
  }) : source = url,
       _sourceType = _SourceType.network,
       package = null;

  const Animg.asset({
    super.key,
    required String asset,
    this.package,
    this.height,
    this.width,
  }) : source = asset,
       _sourceType = _SourceType.asset;

  final String source;
  final String? package;
  final double? height;
  final double? width;
  final _SourceType _sourceType;

  @override
  Widget build(BuildContext context) {
    switch (_sourceType) {
      case _SourceType.asset:
        return Lottie.asset(
          source,
          height: height,
          width: width,
          package: package,
        );
      case _SourceType.network:
        return Lottie.network(
          source,
          height: height,
          width: width,
        );
    }
  }
}
