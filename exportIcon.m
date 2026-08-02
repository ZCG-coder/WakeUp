#import <AppKit/AppKit.h>

int main(int argc, const char *argv[]) {
  if (argc == 1)
    return 1;

  @autoreleasepool {
    NSString *symbolName =
        [NSString stringWithUTF8String:argv[1]]; // Any SF Symbol name
    CGFloat pointSize = 3096.0;                  // Output resolution size

    // Load the SF Symbol with a specific point size and weight
    NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration
        configurationWithPointSize:pointSize
                            weight:NSFontWeightRegular];
    NSImage *image = [[NSImage imageWithSystemSymbolName:symbolName
                                accessibilityDescription:nil]
        imageWithSymbolConfiguration:config];

    if (!image) {
      NSLog(@"Error: Symbol '%@' not found.", symbolName);
      return 1;
    }

    // Convert NSImage to PNG data
    NSData *tiffData = [image TIFFRepresentation];
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *pngData = [bitmap representationUsingType:NSBitmapImageFileTypePNG
                                           properties:@{}];

    // Write to disk
    NSString *outputPath = @"symbol_icon.png";
    [pngData writeToFile:outputPath atomically:YES];

    NSLog(@"Successfully generated %@ (%dx%d)", outputPath, (int)pointSize,
          (int)pointSize);
  }
  return 0;
}
