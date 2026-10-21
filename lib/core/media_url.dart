import 'package:cargo_line_tj/core/brand_constants.dart';

/// Resolve admin/relative/data image URLs for Image.network / memory.
String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  final u = raw.trim();
  if (u.isEmpty) return null;
  if (u.startsWith('data:')) return u;
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) {
    return '${BrandConstants.apiBaseUrl}$u';
  }
  return '${BrandConstants.apiBaseUrl}/$u';
}
