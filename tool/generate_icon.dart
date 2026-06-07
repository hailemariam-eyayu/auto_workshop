// Run with: dart run tool/generate_icon.dart
// Generates a 1024x1024 app icon PNG:
//   - Navy (#1D3557) rounded-square background
//   - Red (#E63946) inner rounded square
//   - White wrench SVG path centered

import 'dart:io';
import 'dart:math';

void main() {
  // We'll write a minimal PNG manually using raw pixel data.
  // Size: 1024x1024
  const size = 1024;
  final pixels = List<List<int>>.generate(
      size, (_) => List<int>.filled(size * 4, 0));

  // Colors
  const navy = [0x1D, 0x35, 0x57, 0xFF];
  const red = [0xE6, 0x39, 0x46, 0xFF];
  const white = [0xFF, 0xFF, 0xFF, 0xFF];

  // Draw background: red rounded square (full size, matches home screen header)
  final bgRadius = size * 0.22;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      if (_inRoundedRect(x, y, 0, 0, size, size, bgRadius)) {
        pixels[y][x * 4] = red[0];
        pixels[y][x * 4 + 1] = red[1];
        pixels[y][x * 4 + 2] = red[2];
        pixels[y][x * 4 + 3] = red[3];
      }
    }
  }

  // No inner square — white wrench directly on red

  // Draw white wrench (simplified geometric shape)
  // Wrench centered at (512,512), ~38% of icon size
  final cx = size / 2;
  final cy = size / 2;
  final wr = size * 0.19; // wrench radius

  // Draw wrench as thick rotated rectangle (handle) + circle head
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      if (_isWrench(x.toDouble(), y.toDouble(), cx, cy, wr)) {
        pixels[y][x * 4] = white[0];
        pixels[y][x * 4 + 1] = white[1];
        pixels[y][x * 4 + 2] = white[2];
        pixels[y][x * 4 + 3] = white[3];
      }
    }
  }

  // Encode as PNG
  final png = _encodePng(pixels, size, size);
  File('assets/icon/app_icon.png').writeAsBytesSync(png);
  File('assets/icon/app_icon_fg.png').writeAsBytesSync(png);
  print('Icons written to assets/icon/');
}

bool _inRoundedRect(
    int px, int py, int rx, int ry, int rw, int rh, double radius) {
  final x = px - rx;
  final y = py - ry;
  if (x < 0 || x >= rw || y < 0 || y >= rh) return false;
  // Check corners
  if (x < radius && y < radius) {
    return _dist(x, y, radius, radius) <= radius;
  }
  if (x > rw - radius && y < radius) {
    return _dist(x, y, rw - radius, radius) <= radius;
  }
  if (x < radius && y > rh - radius) {
    return _dist(x, y, radius, rh - radius) <= radius;
  }
  if (x > rw - radius && y > rh - radius) {
    return _dist(x, y, rw - radius, rh - radius) <= radius;
  }
  return true;
}

double _dist(num x1, num y1, num x2, num y2) {
  final dx = x1 - x2;
  final dy = y1 - y2;
  return sqrt(dx * dx + dy * dy);
}

bool _isWrench(double px, double py, double cx, double cy, double r) {
  // Rotate 45 degrees
  final angle = -pi / 4;
  final rx = (px - cx) * cos(angle) - (py - cy) * sin(angle);
  final ry = (px - cx) * sin(angle) + (py - cy) * cos(angle);

  // Handle: tall thin rectangle
  final handleW = r * 0.28;
  final handleH = r * 1.6;
  if (rx.abs() < handleW && ry > -handleH && ry < handleH) return true;

  // Head circle (top of wrench)
  final headCy = -handleH * 0.75;
  final headR = r * 0.42;
  final holeR = r * 0.22;
  final dHead = _dist(rx, ry, 0, headCy);
  if (dHead <= headR && dHead > holeR) return true;

  // Tail circle (bottom)
  final tailCy = handleH * 0.75;
  final tailR = r * 0.32;
  final tailHoleR = r * 0.16;
  final dTail = _dist(rx, ry, 0, tailCy);
  if (dTail <= tailR && dTail > tailHoleR) return true;

  return false;
}

// ── Minimal PNG encoder ───────────────────────────────────────────────────────

List<int> _encodePng(List<List<int>> pixels, int width, int height) {
  final raw = <int>[];

  // PNG signature
  raw.addAll([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR chunk
  final ihdr = <int>[];
  ihdr.addAll(_int32(width));
  ihdr.addAll(_int32(height));
  ihdr.addAll([8, 6, 0, 0, 0]); // 8-bit RGBA
  raw.addAll(_chunk('IHDR', ihdr));

  // IDAT chunk (raw scanlines with filter byte 0)
  final scanlines = <int>[];
  for (var y = 0; y < height; y++) {
    scanlines.add(0); // filter type None
    scanlines.addAll(pixels[y]);
  }
  final compressed = _deflate(scanlines);
  raw.addAll(_chunk('IDAT', compressed));

  // IEND chunk
  raw.addAll(_chunk('IEND', []));

  return raw;
}

List<int> _chunk(String type, List<int> data) {
  final result = <int>[];
  result.addAll(_int32(data.length));
  final typeBytes = type.codeUnits;
  result.addAll(typeBytes);
  result.addAll(data);
  final crc = _crc32([...typeBytes, ...data]);
  result.addAll(_int32(crc));
  return result;
}

List<int> _int32(int v) => [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ];

// Simple zlib/deflate using dart:io's ZLibEncoder
List<int> _deflate(List<int> data) {
  return ZLibEncoder().convert(data);
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      if (crc & 1 != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
