//
//  ViewController.m
//  CompareLinkMap
//
//  Created by 周末 on 2018/5/11.
//  Copyright © 2018年 周末. All rights reserved.
//

#import "ViewController.h"
#import "LinkMapHandler.h"

@interface ViewController(){
    NSString *linkMap1Path;
    NSString *linkMap2path;
    NSString *keyWord;
    NSString *sortKey;
}
@property (weak) IBOutlet NSTextField *oldFilePath;
@property (weak) IBOutlet NSTextField *theNewFilePath;
@property (weak) IBOutlet NSTextField *keywordTextField;
@property (weak) IBOutlet NSProgressIndicator *IndicatorProgress;
@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;
@property (weak) IBOutlet NSButton *combineLibraryButton; // 合并库
@property (weak) IBOutlet NSPopUpButton *sortKeyButton; // 排序关键字

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.IndicatorProgress.hidden = YES;
    self.resultTextView.editable = NO;
    
    [self.sortKeyButton setTarget:self];
    [self.sortKeyButton setAction:@selector(chooseSortKey:)];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


#pragma mark - Action
- (IBAction)chooseOldFile:(id)sender {
    [LinkMapHandler linkMapPathForChoose:^(NSString *linkMapPath) {
        linkMap1Path = linkMapPath;
        self.oldFilePath.stringValue = [linkMapPath lastPathComponent];
    }];
}

- (IBAction)chooseNewFile:(id)sender {
    [LinkMapHandler linkMapPathForChoose:^(NSString *linkMapPath) {
        linkMap2path = linkMapPath;
        self.theNewFilePath.stringValue = [linkMapPath lastPathComponent];
    }];
}

- (IBAction)chooseResultPath:(id)sender {
    [LinkMapHandler linkMapResultPathForChoose:^(NSString *resultPath) {
        if(self.resultTextView.string){
            NSError *error;
            [self.resultTextView.string writeToFile:resultPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        }
    }];
}

- (IBAction)startCompare:(id)sender {
    if(!linkMap1Path || ![[NSFileManager defaultManager] fileExistsAtPath:linkMap1Path isDirectory:nil] || !linkMap2path || ![[NSFileManager defaultManager] fileExistsAtPath:linkMap2path isDirectory:nil]){
        [self showAlertWithText:@"请选择正确的linkMap文件路径"];
        return;
    }
    
    self.IndicatorProgress.hidden = NO;
    [self.IndicatorProgress startAnimation:self];
    keyWord = self.keywordTextField.stringValue?:@"";
    NSString *content1 = [self parserLinkMap:[NSURL fileURLWithPath:linkMap1Path]];
    NSString *content2 = [self parserLinkMap:[NSURL fileURLWithPath:linkMap2path]];
    BOOL state = self.combineLibraryButton.state;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
       NSString *result = [LinkMapHandler compareLinkMapContent1:content1 linkMapContent2:content2 keyWord:keyWord isOnlyShowLibrary:state sortKeyWord:sortKey];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultTextView.string = result;
            self.IndicatorProgress.hidden = YES;
            [self.IndicatorProgress stopAnimation:self];
        });
    });
}

- (void)chooseSortKey:(id)sender{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    if([btn.title isEqualToString:@"比较结果"]){
        sortKey = @"compare";
    }else if ([btn.title isEqualToString:@"LinkMap1"]){
        sortKey = @"linkMap1";
    }else if ([btn.title isEqualToString:@"LinkMap2"]){
        sortKey = @"linkMap2";
    }
}

#pragma mark - Other
- (void)showAlertWithText:(NSString *)text {
    self.IndicatorProgress.hidden = YES;
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = text;
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}

#pragma mark - Private
- (NSString *)parserLinkMap:(NSURL *)linkMapURL{
         NSString *content = [NSString stringWithContentsOfURL:linkMapURL encoding:NSMacOSRomanStringEncoding error:nil];
        
        BOOL checkSuccess = [LinkMapHandler checkLinkMapContent:content];
        if(!checkSuccess){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithText:@"请选择正确的LinkMap文件"];
            });
            return @"";
        }
        
        return content;
}






@end
