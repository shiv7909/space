import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final inputPath = 'assets/images/space final icon.png';
  final outputPath = 'assets/images/space_icon_scaled.png';

  print('Loading image: $inputPath');
  final bytes = await File(inputPath).readAsBytes();
  final img = decodeImage(bytes);

  if (img == null) {
    print('Failed to load image.');
    return;
  }

  // Find bounding box of non-black pixels
  int minX = img.width;
  int minY = img.height;
  int maxX = 0;
  int maxY = 0;

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final pixel = img.getPixel(x, y);
      // Check if it's strictly not black (considering near-black antialiasing)
      if (pixel.r > 10 || pixel.g > 10 || pixel.b > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Original bounding box: \$minX, \$minY to \$maxX, \$maxY');

  final contentWidth = maxX - minX;
  final contentHeight = maxY - minY;

  // Add 40% padding around the content for the safe zone
  final paddingX = (contentWidth * 0.4).round();
  final paddingY = (contentHeight * 0.4).round();

  // New dimensions
  int finalWidth = contentWidth + (paddingX * 2);
  int finalHeight = contentHeight + (paddingY * 2);

  // Make square
  final dim = finalWidth > finalHeight ? finalWidth : finalHeight;

  // Create a new pure black image of our final dimension
  final finalImg = Image(width: dim, height: dim);
  for (final p in finalImg) {
    p.setRgb(0, 0, 0);
  }

  // Calculate center offsets
  final offsetX = (dim - contentWidth) ~/ 2;
  final offsetY = (dim - contentHeight) ~/ 2;

  // Copy the cropped content into the center of the new image
  compositeImage(
    finalImg,
    img,
    dstX: offsetX,
    dstY: offsetY,
    srcX: minX,
    srcY: minY,
    srcW: contentWidth,
    srcH: contentHeight,
  );

  print('Saving scaled image to: $outputPath (Size: \$dim x \$dim)');
  await File(outputPath).writeAsBytes(encodePng(finalImg));
  print('Done!');
}
