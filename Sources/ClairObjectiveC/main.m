#import <Cocoa/Cocoa.h>

@interface Candidate : NSObject
@property NSURL *url;
@property NSString *category;
@property NSString *detail;
@property NSString *symbol;
@property long long size;
@property BOOL selected;
@end
@implementation Candidate @end

static long long SizeAtURL(NSURL *url) {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSNumber *isDirectory = nil;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    if (![isDirectory boolValue]) {
        NSNumber *size = nil; [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        return size.longLongValue;
    }
    long long total = 0;
    NSDirectoryEnumerator *entries = [manager enumeratorAtURL:url
        includingPropertiesForKeys:@[NSURLFileSizeKey, NSURLIsRegularFileKey]
        options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    for (NSURL *file in entries) {
        NSNumber *regular = nil, *size = nil;
        [file getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
        if (regular.boolValue) { [file getResourceValue:&size forKey:NSURLFileSizeKey error:nil]; total += size.longLongValue; }
    }
    return total;
}

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property NSWindow *window;
@property NSTableView *table;
@property NSTextField *summary;
@property NSTextField *recoverableValue;
@property NSTextField *storageValue;
@property NSProgressIndicator *storageBar;
@property NSButton *cleanButton;
@property NSButton *scanButton;
@property NSPopUpButton *categoryFilter;
@property NSButton *includeXcodeSetting;
@property NSMutableArray<Candidate *> *items;
@end

@implementation AppDelegate

- (NSTextField *)label:(NSString *)text size:(CGFloat)size color:(NSColor *)color {
    NSTextField *field = [NSTextField labelWithString:text];
    field.font = [NSFont systemFontOfSize:size weight:size > 20 ? NSFontWeightBold : NSFontWeightRegular];
    field.textColor = color; return field;
}

- (NSView *)metricCardWithTitle:(NSString *)title value:(NSTextField **)valueOut symbol:(NSString *)symbol {
    NSVisualEffectView *card = [[NSVisualEffectView alloc] init]; card.material = NSVisualEffectMaterialSidebar; card.blendingMode = NSVisualEffectBlendingModeBehindWindow; card.state = NSVisualEffectStateActive; card.wantsLayer = YES; card.layer.cornerRadius = 12;
    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)]; icon.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil]; icon.contentTintColor = NSColor.controlAccentColor;
    NSTextField *titleLabel = [self label:title size:12 color:NSColor.secondaryLabelColor]; NSTextField *value = [self label:@"—" size:22 color:NSColor.labelColor];
    NSStackView *copy = [NSStackView stackViewWithViews:@[titleLabel, value]]; copy.orientation =NSUserInterfaceLayoutOrientationVertical; copy.spacing = 3;
    NSStackView *row = [NSStackView stackViewWithViews:@[icon, copy]]; row.orientation =NSUserInterfaceLayoutOrientationHorizontal; row.spacing = 10; row.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:row]; [NSLayoutConstraint activateConstraints:@[[row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16], [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16], [row.centerYAnchor constraintEqualToAnchor:card.centerYAnchor], [card.heightAnchor constraintEqualToConstant:68]]];
    *valueOut = value; return card;
}

- (NSArray<Candidate *> *)visibleItems {
    NSString *filter = self.categoryFilter.selectedItem.title;
    if ([filter isEqualToString:@"Tous les éléments"]) return self.items;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category == %@", filter]; return [self.items filteredArrayUsingPredicate:predicate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.items = NSMutableArray.array;
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 920, 680)
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Clair"; self.window.minSize = NSMakeSize(680, 460);
    [self.window center];
    NSMenu *mainMenu = NSMenu.new; NSMenuItem *appItem = NSMenuItem.new; [mainMenu addItem:appItem]; NSMenu *appMenu = NSMenu.new;
    [appMenu addItemWithTitle:@"Réglages…" action:@selector(showSettings:) keyEquivalent:@","]; [appMenu addItem:[NSMenuItem separatorItem]]; [appMenu addItemWithTitle:@"Quitter Clair" action:@selector(terminate:) keyEquivalent:@"q"]; appItem.submenu = appMenu; NSApp.mainMenu = mainMenu;

    NSView *content = self.window.contentView;
    NSStackView *root = [NSStackView stackViewWithViews:@[]];
    root.orientation =NSUserInterfaceLayoutOrientationVertical; root.spacing = 12;
    root.edgeInsets = NSEdgeInsetsMake(24, 28, 20, 28); root.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:root];
    [NSLayoutConstraint activateConstraints:@[
        [root.leadingAnchor constraintEqualToAnchor:content.leadingAnchor], [root.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [root.topAnchor constraintEqualToAnchor:content.topAnchor], [root.bottomAnchor constraintEqualToAnchor:content.bottomAnchor]
    ]];

    NSStackView *top = [NSStackView stackViewWithViews:@[]]; top.orientation =NSUserInterfaceLayoutOrientationHorizontal;
    NSImageView *appIcon = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)]; appIcon.image = [NSImage imageWithSystemSymbolName:@"sparkles" accessibilityDescription:nil]; appIcon.contentTintColor = NSColor.controlAccentColor;
    NSStackView *titles = [NSStackView stackViewWithViews:@[[self label:@"Clair" size:30 color:NSColor.labelColor],
        [self label:@"Libérez de l’espace, sans perdre le contrôle." size:13 color:NSColor.secondaryLabelColor]]];
    titles.orientation =NSUserInterfaceLayoutOrientationVertical; titles.spacing = 4;
    NSStackView *hero = [NSStackView stackViewWithViews:@[appIcon, titles]]; hero.orientation =NSUserInterfaceLayoutOrientationHorizontal; hero.spacing = 12;
    self.scanButton = [NSButton buttonWithTitle:@"Analyser" target:self action:@selector(scan:)]; self.scanButton.bezelStyle = NSBezelStyleRounded;
    [top addArrangedSubview:hero]; [top addArrangedSubview:self.scanButton]; [top setHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [root addArrangedSubview:top];

    NSTextField *reclaimValue = nil, *storageValue = nil; NSView *reclaim = [self metricCardWithTitle:@"Espace à examiner" value:&reclaimValue symbol:@"sparkles"]; NSView *storage = [self metricCardWithTitle:@"Espace disponible" value:&storageValue symbol:@"internaldrive"]; self.recoverableValue = reclaimValue; self.storageValue = storageValue;
    NSStackView *cards = [NSStackView stackViewWithViews:@[reclaim, storage]]; cards.orientation =NSUserInterfaceLayoutOrientationHorizontal; cards.distribution = NSStackViewDistributionFillEqually; cards.spacing = 12; [root addArrangedSubview:cards];

    self.table = [[NSTableView alloc] init]; self.table.delegate = self; self.table.dataSource = self;
    NSArray *columns = @[@[@"", @"selection", @42], @[@"Élément", @"name", @315], @[@"Origine", @"category", @170], @[@"Taille", @"size", @100]];
    for (NSArray *definition in columns) { NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:definition[1]]; column.title = definition[0]; column.width = [definition[2] doubleValue]; [self.table addTableColumn:column]; }
    self.table.headerView = [[NSTableHeaderView alloc] init]; self.table.usesAlternatingRowBackgroundColors = NO; self.table.rowHeight = 48;
    NSScrollView *scroll = [[NSScrollView alloc] init]; scroll.documentView = self.table; scroll.hasVerticalScroller = YES; scroll.borderType = NSBezelBorder;
    [root addArrangedSubview:scroll]; [scroll.heightAnchor constraintGreaterThanOrEqualToConstant:280].active = YES;

    NSStackView *bottom = [NSStackView stackViewWithViews:@[]]; bottom.orientation =NSUserInterfaceLayoutOrientationHorizontal;
    self.summary = [self label:@"Analysez les zones temporaires et récupérables de votre Mac." size:13 color:NSColor.secondaryLabelColor];
    self.categoryFilter = [[NSPopUpButton alloc] init]; [self.categoryFilter addItemWithTitle:@"Tous les éléments"]; self.categoryFilter.target = self; self.categoryFilter.action = @selector(filterChanged:);
    self.cleanButton = [NSButton buttonWithTitle:@"Déplacer vers la Corbeille" target:self action:@selector(clean:)]; self.cleanButton.enabled = NO;
    [bottom addArrangedSubview:self.summary]; [bottom addArrangedSubview:self.categoryFilter]; [bottom addArrangedSubview:self.cleanButton];
    [root addArrangedSubview:bottom];
    [self.window makeKeyAndOrderFront:nil];
}

- (void)scan:(id)sender {
    self.summary.stringValue = @"Analyse des données temporaires et récupérables…"; self.cleanButton.enabled = NO; self.scanButton.enabled = NO; [self.items removeAllObjects]; [self.table reloadData];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSFileManager *fm = NSFileManager.defaultManager; NSURL *home = fm.homeDirectoryForCurrentUser;
        NSDate *weekOld = [NSDate dateWithTimeIntervalSinceNow:-(7 * 24 * 60 * 60)], *monthOld = [NSDate dateWithTimeIntervalSinceNow:-(30 * 24 * 60 * 60)]; NSMutableArray *found = NSMutableArray.array;
        // Ces sources excluent volontairement Documents, Photos, Mail et les données applicatives.
        NSMutableArray *roots = [@[@[@"Caches", [home URLByAppendingPathComponent:@"Library/Caches"], weekOld, @"Données temporaires non modifiées depuis 7 jours", @"bolt.fill"], @[@"Journaux", [home URLByAppendingPathComponent:@"Library/Logs"], monthOld, @"Journaux de diagnostic âgés de plus de 30 jours", @"doc.text"], @[@"Corbeille", [home URLByAppendingPathComponent:@".Trash"], [NSNull null], @"Éléments déjà placés dans la Corbeille", @"trash.fill"], @[@"Installateurs", [home URLByAppendingPathComponent:@"Downloads"], monthOld, @"Images disque et archives âgées de plus de 30 jours", @"shippingbox.fill"]] mutableCopy];
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"includeXcode"]) [roots addObject:@[@"Données Xcode", [home URLByAppendingPathComponent:@"Library/Developer/Xcode/DerivedData"], monthOld, @"Données de compilation Xcode non modifiées depuis 30 jours", @"hammer.fill"]];
        for (NSArray *entry in roots) {
            NSArray<NSURL *> *children = [fm contentsOfDirectoryAtURL:entry[1] includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
            for (NSURL *url in children) {
                NSArray *installerExtensions = @[@"dmg", @"pkg", @"zip"];
                if ([entry[0] isEqual:@"Installateurs"] && ![installerExtensions containsObject:url.pathExtension.lowercaseString]) continue;
                NSDate *date = nil; [url getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];
                if (entry[2] != [NSNull null] && date && [date compare:entry[2]] == NSOrderedDescending) continue;
                long long size = SizeAtURL(url); if (size < 1) continue;
                Candidate *candidate = Candidate.new; candidate.url = url; candidate.category = entry[0]; candidate.detail = entry[3]; candidate.symbol = entry[4]; candidate.size = size; candidate.selected = NO; [found addObject:candidate];
            }
        }
        [found sortUsingComparator:^NSComparisonResult(Candidate *a, Candidate *b) { return a.size > b.size ? NSOrderedAscending : NSOrderedDescending; }];
        dispatch_async(dispatch_get_main_queue(), ^{ self.items = found; self.scanButton.enabled = YES; [self.categoryFilter removeAllItems]; [self.categoryFilter addItemWithTitle:@"Tous les éléments"]; for (NSString *name in @[@"Caches", @"Journaux", @"Corbeille", @"Installateurs", @"Données Xcode"]) if ([found filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %@", name]].count) [self.categoryFilter addItemWithTitle:name]; [self.table reloadData]; [self refreshSummary]; });
    });
}

- (void)refreshSummary {
    long long selectedBytes = 0, totalBytes = 0; NSInteger count = 0; for (Candidate *item in self.items) { totalBytes += item.size; if (item.selected) { selectedBytes += item.size; count++; } }
    NSDictionary *fs = [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil]; long long free = [fs[NSFileSystemFreeSize] longLongValue]; long long capacity = [fs[NSFileSystemSize] longLongValue];
    self.recoverableValue.stringValue = self.items.count ? [NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile] : @"Rien à examiner";
    self.storageValue.stringValue = capacity ? [NSString stringWithFormat:@"%@ libres", [NSByteCountFormatter stringFromByteCount:free countStyle:NSByteCountFormatterCountStyleFile]] : @"—";
    self.summary.stringValue = self.items.count ? [NSString stringWithFormat:@"%ld élément(s) sélectionné(s) · %@ à déplacer vers la Corbeille", (long)count, [NSByteCountFormatter stringFromByteCount:selectedBytes countStyle:NSByteCountFormatterCountStyleFile]] : @"Aucun élément temporaire ou ancien n’a été détecté.";
    self.cleanButton.enabled = count > 0;
}

- (void)clean:(id)sender {
    NSMutableArray *selected = NSMutableArray.array; for (Candidate *item in self.items) if (item.selected) [selected addObject:item];
    NSAlert *alert = NSAlert.new; alert.messageText = @"Déplacer les éléments sélectionnés ?"; alert.informativeText = @"Ils resteront récupérables dans la Corbeille jusqu’à ce que vous la vidiez."; [alert addButtonWithTitle:@"Déplacer vers la Corbeille"]; [alert addButtonWithTitle:@"Annuler"];
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    NSFileManager *fm = NSFileManager.defaultManager; NSInteger moved = 0;
    for (Candidate *item in selected) { if ([fm trashItemAtURL:item.url resultingItemURL:nil error:nil]) { [self.items removeObject:item]; moved++; } }
    [self.table reloadData]; [self refreshSummary];
    NSAlert *done = NSAlert.new; done.messageText = [NSString stringWithFormat:@"%ld élément(s) déplacé(s)", (long)moved]; done.informativeText = @"Aucune suppression définitive n’a été effectuée."; [done runModal];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { return self.visibleItems.count; }
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    Candidate *item = self.visibleItems[row]; NSString *key = column.identifier;
    if ([key isEqual:@"selection"]) { NSButton *check = [NSButton checkboxWithTitle:@"" target:self action:@selector(toggle:)]; check.tag = row; check.state = item.selected ? NSControlStateValueOn : NSControlStateValueOff; return check; }
    if ([key isEqual:@"category"]) { NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)]; icon.image = [NSImage imageWithSystemSymbolName:item.symbol accessibilityDescription:nil]; icon.contentTintColor = NSColor.secondaryLabelColor; NSTextField *text = [NSTextField labelWithString:item.category]; NSStackView *row = [NSStackView stackViewWithViews:@[icon, text]]; row.orientation =NSUserInterfaceLayoutOrientationHorizontal; row.spacing = 7; return row; }
    NSTextField *cell = [NSTextField labelWithString:[key isEqual:@"name"] ? item.url.lastPathComponent : [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]]; cell.lineBreakMode = NSLineBreakByTruncatingMiddle; return cell;
}
- (void)toggle:(NSButton *)sender { self.visibleItems[sender.tag].selected = sender.state == NSControlStateValueOn; [self refreshSummary]; }
- (void)filterChanged:(id)sender { [self.table reloadData]; }
- (void)showSettings:(id)sender {
    NSAlert *settings = NSAlert.new; settings.messageText = @"Réglages"; settings.informativeText = @"Clair ne parcourt jamais Documents, Photos, Mail ou les données d’applications.";
    NSButton *xcode = [NSButton checkboxWithTitle:@"Inclure les données de compilation Xcode anciennes" target:nil action:nil]; xcode.state = [NSUserDefaults.standardUserDefaults boolForKey:@"includeXcode"] ? NSControlStateValueOn : NSControlStateValueOff; self.includeXcodeSetting = xcode;
    NSStackView *accessory = [NSStackView stackViewWithViews:@[xcode, [self label:@"Les éléments restent toujours dans la Corbeille après nettoyage." size:12 color:NSColor.secondaryLabelColor]]]; accessory.orientation =NSUserInterfaceLayoutOrientationVertical; accessory.spacing = 10; settings.accessoryView = accessory; [settings addButtonWithTitle:@"Terminé"]; [settings runModal]; [NSUserDefaults.standardUserDefaults setBool:xcode.state == NSControlStateValueOn forKey:@"includeXcode"];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end

int main(int argc, const char * argv[]) { @autoreleasepool { NSApplication *app = NSApplication.sharedApplication; app.delegate = AppDelegate.new; [app run]; } return 0; }
