import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  // Create a simple test image with colored pixels
  final image = img.Image(width: 800, height: 600);
  
  // Fill with gradient pattern
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final r = (x / image.width * 255).round();
      final g = (y / image.height * 255).round();
      final b = 128;
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  
  // Generate JPEG
  final jpegBytes = img.encodeJpg(image, quality: 85);
  File('test_image.jpg').writeAsBytesSync(jpegBytes);
  print('Created test_image.jpg (${jpegBytes.length} bytes)');
  
  // Generate PNG
  final pngBytes = img.encodePng(image);
  File('test_image.png').writeAsBytesSync(pngBytes);
  print('Created test_image.png (${pngBytes.length} bytes)');
  
  // Create small test image
  final smallImage = img.Image(width: 200, height: 150);
  img.fill(smallImage, color: img.ColorRgb8(100, 150, 200));
  
  final smallJpeg = img.encodeJpg(smallImage, quality: 85);
  File('small_test.jpg').writeAsBytesSync(smallJpeg);
  print('Created small_test.jpg (${smallJpeg.length} bytes)');
  
  // Create large test image (for size limit testing)
  final largeImage = img.Image(width: 4000, height: 3000);
  for (var y = 0; y < largeImage.height; y++) {
    for (var x = 0; x < largeImage.width; x++) {
      largeImage.setPixelRgb(x, y, x % 256, y % 256, (x + y) % 256);
    }
  }
  
  final largeJpeg = img.encodeJpg(largeImage, quality: 95);
  File('large_test.jpg').writeAsBytesSync(largeJpeg);
  print('Created large_test.jpg (${largeJpeg.length} bytes)');
}
