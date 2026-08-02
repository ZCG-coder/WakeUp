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
- (void)updateStrings {
  NSStatusBarButton *button = self.statusItem.button;

  if (self.sleepStatCode == 1) {
    self.sleepStatus = @"Sleep Enabled";
    self.sleepToggleStatus = @"Disable Sleep";
    self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug"
                                 accessibilityDescription:@"WakeUp Settings"];
  } else {
    self.sleepStatus = @"Sleep Disabled";
    self.sleepToggleStatus = @"Enable Sleep";
    self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug.fill"
                                 accessibilityDescription:@"WakeUp Settings"];
  }
  button.image = self.buttonImage;

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
  self.sleepStatCode = 1;
  [self updateStrings];

  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  NSStatusBarButton *button = self.statusItem.button;

  self.buttonImage = [NSImage imageWithSystemSymbolName:@"mug"
                               accessibilityDescription:@"WakeUp Settings"];
  if (button) {
    button.image = self.buttonImage;
  }

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
