#include <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>

#define PAD 5

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong, nonatomic) NSStatusItem *statusItem;
@property(strong, nonatomic) NSImage *buttonImage;

@property(strong) NSString *sleepStatus;
@property(strong) NSString *sleepToggleStatus;
@property(strong, nonatomic) NSMenuItem *sleepToggle;
@property(strong, nonatomic) NSMenuItem *sleepLabel;

@property(assign) int sleepStatCode;
@end

@implementation AppDelegate
- (void)readSystemConfig {
  NSAppleScript *appleScript =
      [[NSAppleScript alloc] initWithSource:@"do shell script \"pmset -g\""];
  NSDictionary *errorDict = nil;
  NSAppleEventDescriptor *resultDescriptor =
      [appleScript executeAndReturnError:&errorDict];

  if (errorDict) {
    [self showErrorBox:@"An error occured"];
    return;
  }

  NSString *out = resultDescriptor.stringValue;
  NSError *error = NULL;
  NSRegularExpression *expr = [NSRegularExpression
      regularExpressionWithPattern:@"^\\s+SleepDisabled\\s+([01])"
                           options:NSRegularExpressionAnchorsMatchLines
                             error:&error];
  if (error) {
    NSLog(@"regex: %ld", (long)[error code]);
    NSLog(@"regex: %@", [error description]);
  }

  NSTextCheckingResult *match =
      [expr firstMatchInString:out
                       options:0
                         range:NSMakeRange(0, [out length])];
  // sleep is probably disabled
  if (!match)
    return;

  if ([match numberOfRanges] > 1) {
    NSRange range = [match rangeAtIndex:1];
    if (range.location != NSNotFound) {
      NSString *group1String = [out substringWithRange:range];
      if ([group1String isEqual:@"1"]) {
        self.sleepStatCode = 0;
        NSLog(@"Sleep is diabled");
      }
    }
  }
}

- (void)updateStrings {
  NSStatusBarButton *button = self.statusItem.button;

  if (self.sleepStatCode == 1) {
    self.sleepStatus = @"Sleep Enabled";
    self.sleepToggleStatus = @"Disable Sleep";
    self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug"
                                 accessibilityDescription:self.sleepStatus];
  } else {
    self.sleepStatus = @"Sleep Disabled";
    self.sleepToggleStatus = @"Enable Sleep";
    self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug.fill"
                                 accessibilityDescription:self.sleepStatus];
  }
  [button setImage:self.buttonImage];

  [self.sleepToggle setTitle:self.sleepToggleStatus];
  [self.sleepLabel setTitle:self.sleepStatus];
}

- (BOOL)runSudoCommand:(NSString *)command {
  NSString *escapedCommand =
      [command stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

  NSString *scriptSource = [NSString
      stringWithFormat:@"do shell script \"%@\" with administrator privileges",
                       escapedCommand];

  NSAppleScript *appleScript =
      [[NSAppleScript alloc] initWithSource:scriptSource];
  NSDictionary *errorDict = nil;

  [appleScript executeAndReturnError:&errorDict];

  if (errorDict) {
    [self showErrorBox:@"An error occured"];
    return NO;
  }

  return YES;
}

- (void)showErrorBox:(NSString *)error {
  NSString *escapedError = [error stringByReplacingOccurrencesOfString:@"\""
                                                            withString:@"\\\""];

  NSString *scriptSource =
      [NSString stringWithFormat:@"display dialog \"%@\"", escapedError];

  NSAppleScript *appleScript =
      [[NSAppleScript alloc] initWithSource:scriptSource];

  [appleScript executeAndReturnError:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];
  NSStatusBarButton *button = self.statusItem.button;

  self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug"
                               accessibilityDescription:@"WakeUp Settings"];
  if (button) {
    [button setImage:self.buttonImage];
  }
  self.sleepStatCode = 1;
  [self readSystemConfig];
  [self updateStrings];

  NSMenu *menu = [[NSMenu alloc] init];
  self.sleepToggle = [[NSMenuItem alloc] initWithTitle:self.sleepToggleStatus
                                                action:@selector(toggleSleep:)
                                         keyEquivalent:@""];
  self.sleepLabel = [[NSMenuItem alloc] initWithTitle:self.sleepStatus
                                               action:nil
                                        keyEquivalent:@""];

  [menu addItemWithTitle:@"WakeUp by Andy Zhang"
                  action:@selector(nothing:)
           keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:self.sleepLabel];
  [menu addItem:self.sleepToggle];
  [menu addItem:[NSMenuItem separatorItem]];

  [menu addItemWithTitle:@"Quit"
                  action:@selector(terminate:)
           keyEquivalent:@"q"];

  self.statusItem.menu = menu;
}

- (void)nothing:(id)sender {
}

- (void)toggleSleep:(id)sender {
  NSLog(@"Toggle");

  BOOL status;
  if (self.sleepStatCode == 1)
    status = [self runSudoCommand:@"pmset -a disablesleep 1"];
  else
    status = [self runSudoCommand:@"pmset -a disablesleep 0"];

  if (status) {
    self.sleepStatCode = (self.sleepStatCode == 1) ? 0 : 1;
    [self updateStrings];
  }
}
@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [app setDelegate:delegate];
    [app run];
  }
  return 0;
}
