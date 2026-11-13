#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

@interface ProbeController : UIViewController <MTKViewDelegate>
@property(nonatomic,strong) MTKView *metalView;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) id<MTLCommandQueue> queue;
@property(nonatomic,strong) id<MTLRenderPipelineState> pipeline;
@property(nonatomic) CFTimeInterval last;
@property(nonatomic) NSUInteger submitted;
@end
@implementation ProbeController
- (void)viewDidLoad {
    [super viewDidLoad];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self.view.backgroundColor = UIColor.blackColor;
    self.status = [[UILabel alloc] init];
    self.status.textColor = UIColor.whiteColor;
    self.status.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightMedium];
    self.status.numberOfLines = 0;
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    if (device) {
        self.metalView = [[MTKView alloc] initWithFrame:self.view.bounds device:device];
        self.metalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.metalView.clearColor = MTLClearColorMake(0.025, 0.025, 0.05, 1);
        self.metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        self.metalView.preferredFramesPerSecond = 60;
        self.queue = [device newCommandQueue];
        id<MTLLibrary> library = [device newDefaultLibrary];
        MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
        desc.vertexFunction = [library newFunctionWithName:@"probe_vertex"];
        desc.fragmentFunction = [library newFunctionWithName:@"probe_fragment"];
        desc.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
        NSError *error = nil;
        if (desc.vertexFunction && desc.fragmentFunction)
            self.pipeline = [device newRenderPipelineStateWithDescriptor:desc error:&error];
        if (self.pipeline && self.queue) {
            [self.view addSubview:self.metalView];
            self.metalView.delegate = self;
            self.last = CACurrentMediaTime();
            self.status.text = [NSString stringWithFormat:@"NXNative hardware probe\nMetal: %@\nWaiting for frames...\nNo game data", device.name];
        } else {
            self.status.text = [NSString stringWithFormat:@"Metal initialization failed: %@", error.localizedDescription ?: @"missing pipeline or command queue"];
        }
    } else self.status.text = @"No Metal device available";
    [self.view addSubview:self.status];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[self.status.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [self.status.topAnchor constraintEqualToAnchor:safe.topAnchor constant:20],
        [self.status.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-20]]];
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}
- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        if (!self.pipeline) return;
        MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
        id<CAMetalDrawable> drawable = view.currentDrawable;
        if (!pass || !drawable) return;
        id<MTLCommandBuffer> command = [self.queue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
        if (!encoder) return;
        [encoder setRenderPipelineState:self.pipeline];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [encoder endEncoding];
        [command presentDrawable:drawable];
        [command commit];
        self.submitted++;
        CFTimeInterval now = CACurrentMediaTime(), elapsed = now - self.last;
        if (elapsed >= 1.0) {
            self.status.text = [NSString stringWithFormat:@"NXNative hardware probe\nMetal: %@\nDrawable: %.0f x %.0f\nSubmitted frames/s: %.1f\nTriangle test only; no game data", view.device.name, view.drawableSize.width, view.drawableSize.height, self.submitted / elapsed];
            self.submitted = 0;
            self.last = now;
        }
    }
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation SceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [ProbeController new];
    [self.window makeKeyAndVisible];
}
@end
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)app configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:session.role];
    configuration.delegateClass = SceneDelegate.class;
    return configuration;
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class)); }
}
