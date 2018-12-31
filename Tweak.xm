@interface FBRootWindow
-(id)initWithDisplayConfiguration:(id)conf;
@end

@interface OHWMenuButton : UIButton
+(id)buttonWithType:(int)type;
-(void)setPosition:(int)pos;
@end

@interface OneHandWizardWindow : UIWindow
-(id)initWithDisplayConfiguration:(id)conf;
-(id)menuButtonPressed:(id)smth;
-(id)setupSwitchGrabberView;
-(id)blurredWallpaperView;
-(id)setupGrabberView;
@end

@interface UIImage (OHWFix)
+(id)OHWImageWithName:(id)name;
@end

@interface OHWSettings
-(id)sharedSettings;
-(int)mode;
-(void)setInScreenshotMode:(int)mode;
@end

@interface SpringBoard
-(id)_simulateLockButtonPress;
-(void)takeScreenshot;
+(id)sharedApplication;
@end

@interface SBCoverSheetPresentationManager
+(id)sharedInstance;
-(BOOL)isVisible;
-(void)setCoverSheetPresented:(BOOL)pre animated:(BOOL)an withCompletion:(id)comp ;
@end

@interface UIRemoteKeyboardWindow
-(void)_attachSceneLayer;
-(void)attachBindable;
@end

@interface SBLockScreenManager
+(id)sharedInstance;
-(BOOL)isUILocked;
-(id)lockScreenViewController;
@end

@interface SBReachabilityManager
-(void)deactivateOneHandWizardWithCompletion:(id)comp;
-(void)activateOneHandWizardWithCompletion:(id)comp;
@end

%hook FBRootWindow
-(id)initWithDisplay:(id)display {
    return [self initWithDisplayConfiguration:display];
}
%end

%hook OneHandWizardWindow

-(id)initWithDisplay:(id)display {
    @autoreleasepool {
        if (self = [self initWithDisplayConfiguration: display]) {
            
            UIView *wall = [self blurredWallpaperView];
            if (wall) {
                [self insertSubview:wall atIndex:0];
            }
            OHWMenuButton *button = [%c(OHWMenuButton) buttonWithType:0];
   
            UIImage *image = [UIImage OHWImageWithName:@"menu"];
            [button setImage:image forState:0];
            [button addTarget:self action:@selector(menuButtonPressed:) forControlEvents:64];
            
            OHWSettings *settings = [%c(OHWSettings) sharedSettings];
    
            [button setPosition:([settings mode] != 0)];
            [button setTag:102];
            MSHookIvar<OHWMenuButton *>(self, "_menuButton") = button;

            [self addSubview:button];
            [self setupGrabberView];
            [self setupSwitchGrabberView];
        }
        return self;
    }
}

-(void)openNC {
    [self menuButtonPressed:0];
    SBCoverSheetPresentationManager *sncc = [%c(SBCoverSheetPresentationManager) sharedInstance];
    if ([sncc isVisible]) {
        [sncc setCoverSheetPresented:NO animated:YES withCompletion:nil];
    }
    else {
        [sncc setCoverSheetPresented:YES animated:YES withCompletion:nil];
    }
}

-(void)createScreenshot {
    [self menuButtonPressed:0];
    
    [[%c(SBReachabilityManager) sharedInstance] deactivateOneHandWizardWithCompletion:^{
        
        [[%c(SpringBoard) sharedApplication] takeScreenshot];
        
        BOOL locked = [[%c(SBLockScreenManager) sharedInstance] isUILocked];
        if (!locked) {
            OHWSettings *settings = [%c(OHWSettings) sharedSettings];
            [settings setInScreenshotMode: 0];
            
            dispatch_after(dispatch_time(0, 1000000000), dispatch_get_main_queue(), ^{
                [[%c(SBReachabilityManager) sharedInstance] activateOneHandWizardWithCompletion:nil];
            });
            
        }
    }];
}
%end

%hook UIRemoteKeyboardWindow
%new
-(void)_attachSceneLayer {
    // dunno if same thing but it doesn't make the device go up in flames - crash i mean
    return [self attachBindable];
}
%end

%hook SBBacklightController
// this is not a real fix
// but it works in our specific case
%new
-(void)resetLockScreenIdleTimerWithDuration:(double)dur {
    if (dur == 0.0) {
        [((SpringBoard*)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}
%end

// random fix for something that happened to me
%hook __NSArrayI
%new
// ...
-(BOOL)isHidden {
    return false;
}
%end
