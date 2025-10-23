import 'dart:io';
import 'package:image/image.dart' as img;

/// Enhanced Chroma Key Processor - Removes ALL green shades using green dominance detection
///
/// Usage: dart run tools/chroma_key_processor_v2.dart <input.png> <output.png>
///
/// Example: dart run tools/chroma_key_processor_v2.dart assets/animations/angels_grace.png assets/animations/angels_grace_transparent.png

void main(List<String> args) {
  if (args.length < 2) {
    print(
        'Usage: dart run tools/chroma_key_processor_v2.dart <input.png> <output.png>');
    print('');
    print(
        'This enhanced version removes ALL green shades (#00FF00, #30D820, #33DE21, etc.)');
    print('');
    print('Example:');
    print(
        '  dart run tools/chroma_key_processor_v2.dart assets/animations/angels_grace.png assets/animations/angels_grace_transparent.png');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  print('🎬 Enhanced Chroma Key Processor V2');
  print('━' * 50);
  print('Input:  $inputPath');
  print('Output: $outputPath');
  print('Method: Green Dominance Detection (removes ALL green shades)');
  print('━' * 50);

  try {
    // Load image
    print('\n📂 Loading image...');
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      print('❌ Error: Input file not found: $inputPath');
      exit(1);
    }

    final bytes = inputFile.readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) {
      print('❌ Error: Failed to decode image');
      exit(1);
    }

    print('✅ Image loaded: ${image.width}x${image.height}');

    // Process image
    print('\n🔄 Processing pixels...');
    final result = removeAllGreenShades(image);

    print('✅ Processing complete');

    // Save result
    print('\n💾 Saving output...');
    final outputFile = File(outputPath);
    outputFile.writeAsBytesSync(img.encodePng(result));
    print('✅ Saved to: $outputPath');

    print('\n🎉 Done!');
  } catch (e, stack) {
    print('❌ Error: $e');
    print(stack);
    exit(1);
  }
}

/// Remove ALL green shades using green dominance detection
img.Image removeAllGreenShades(img.Image source) {
  int pixelsProcessed = 0;
  int pixelsRemoved = 0;
  int pixelsFeathered = 0;

  // Create output image with alpha channel
  final result = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4, // RGBA
  );

  // Process each pixel
  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);

      // Get RGB values (0-255)
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = pixel.a.toInt();

      // Check if this pixel has ANY green tint
      // Remove if G is higher than BOTH R and B (even slightly)
      final isGreenish = g > r && g > b;

      int finalR = r;
      int finalG = g;
      int finalB = b;
      int finalA = a;

      if (isGreenish) {
        // ANY greenish pixel must be removed completely
        // No feathering - hard removal to eliminate all green tints
        finalR = 0;
        finalG = 0;
        finalB = 0;
        finalA = 0;
        pixelsRemoved++;
      }

      // Set pixel in result image
      result.setPixelRgba(x, y, finalR, finalG, finalB, finalA);
      pixelsProcessed++;
    }

    // Progress indicator
    if ((y + 1) % 50 == 0 || y == source.height - 1) {
      final progress = ((y + 1) / source.height * 100).toStringAsFixed(1);
      stdout.write('\r  Progress: $progress% ');
    }
  }

  print(''); // New line after progress
  print('\n📊 Statistics:');
  print('  Total pixels:     $pixelsProcessed');
  print(
      '  Removed (green):  $pixelsRemoved (${(pixelsRemoved / pixelsProcessed * 100).toStringAsFixed(1)}%)');
  print(
      '  Feathered (edge): $pixelsFeathered (${(pixelsFeathered / pixelsProcessed * 100).toStringAsFixed(1)}%)');
  print(
      '  Kept (content):   ${pixelsProcessed - pixelsRemoved - pixelsFeathered} (${((pixelsProcessed - pixelsRemoved - pixelsFeathered) / pixelsProcessed * 100).toStringAsFixed(1)}%)');

  return result;
}
