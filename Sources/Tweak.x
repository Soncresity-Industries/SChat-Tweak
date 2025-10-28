#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Fonts.h"
#import "LoaderConfig.h"
#import "Logger.h"
#import "Settings.h"
#import "Themes.h"
#import "Utils.h"

static NSURL         *source;
static NSString      *schatPatchesBundlePath;
static NSURL         *pyoncordDirectory;
static LoaderConfig  *loaderConfig;
static NSTimeInterval shakeStartTime = 0;
static BOOL           isShaking      = NO;
id                    gBridge        = nil;

%hook RCTCxxBridge

- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async
{
    if (![url.absoluteString containsString:@"main.jsbundle"])
    {
        return %orig;
    }

    gBridge = self;
    SChatLog(@"Stored bridge reference: %@", gBridge);

    NSBundle *schatPatchesBundle = [NSBundle bundleWithPath:schatPatchesBundlePath];
    if (!schatPatchesBundle)
    {
        SChatLog(@"Failed to load SChatPatches bundle from path: %@", schatPatchesBundlePath);
        showErrorAlert(@"Loader Error",
                       @"Failed to initialize mod loader. Please reinstall the tweak.", nil);
        return %orig;
    }

    NSURL *patchPath = [schatPatchesBundle URLForResource:@"payload-base" withExtension:@"js"];
    if (!patchPath)
    {
        SChatLog(@"Failed to find payload-base.js in bundle");
        showErrorAlert(@"Loader Error",
                       @"Failed to initialize mod loader. Please reinstall the tweak.", nil);
        return %orig;
    }

    NSData *patchData = [NSData dataWithContentsOfURL:patchPath];
    SChatLog(@"Injecting loader");
    %orig(patchData, source, YES);

    __block NSData *bundle =
        [NSData dataWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"bundle.js"]];

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);

    NSURL *bundleUrl;
    if (loaderConfig.customLoadUrlEnabled && loaderConfig.customLoadUrl)
    {
        bundleUrl = loaderConfig.customLoadUrl;
        SChatLog(@"Using custom load URL: %@", bundleUrl.absoluteString);
    }
    else
    {
        bundleUrl = [NSURL
            URLWithString:@"https://raw.githubusercontent.com/Soncresity-Industries/SChat-builds/main/schat.min.js"];
        SChatLog(@"Using default bundle URL: %@", bundleUrl.absoluteString);
    }

    NSMutableURLRequest *bundleRequest =
        [NSMutableURLRequest requestWithURL:bundleUrl
                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                            timeoutInterval:3.0];

    NSString *bundleEtag = [NSString
        stringWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"etag.txt"]
                       encoding:NSUTF8StringEncoding
                          error:nil];
    if (bundleEtag && bundle)
    {
        [bundleRequest setValue:bundleEtag forHTTPHeaderField:@"If-None-Match"];
    }

    NSURLSession *session = [NSURLSession
        sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session
        dataTaskWithRequest:bundleRequest
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if ([response isKindOfClass:[NSHTTPURLResponse class]])
              {
                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                  if (httpResponse.statusCode == 200)
                  {
                      bundle = data;
                      [bundle
                          writeToURL:[pyoncordDirectory URLByAppendingPathComponent:@"bundle.js"]
                          atomically:YES];

                      NSString *etag = [httpResponse.allHeaderFields objectForKey:@"Etag"];
                      if (etag)
                      {
                          [etag
                              writeToURL:[pyoncordDirectory URLByAppendingPathComponent:@"etag.txt"]
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
                      }
                  }
              }
              dispatch_group_leave(group);
          }] resume];

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    NSData *themeData =
        [NSData dataWithContentsOfURL:[pyoncordDirectory
                                          URLByAppendingPathComponent:@"current-theme.json"]];
    if (themeData)
    {
        NSError      *jsonError;
        NSDictionary *themeDict = [NSJSONSerialization JSONObjectWithData:themeData
                                                                  options:0
                                                                    error:&jsonError];
        if (!jsonError)
        {
            SChatLog(@"Loading theme data...");
            if (themeDict[@"data"])
            {
                NSDictionary *data = themeDict[@"data"];
                if (data[@"semanticColors"] && data[@"rawColors"])
                {
                    SChatLog(@"Initializing theme colors from theme data");
                    initializeThemeColors(data[@"semanticColors"], data[@"rawColors"]);
                }
            }

            NSString *jsCode =
                [NSString stringWithFormat:@"globalThis.__PYON_LOADER__.storedTheme=%@",
                                           [[NSString alloc] initWithData:themeData
                                                                 encoding:NSUTF8StringEncoding]];
            %orig([jsCode dataUsingEncoding:NSUTF8StringEncoding], source, async);
        }
        else
        {
            SChatLog(@"Error parsing theme JSON: %@", jsonError);
        }
    }
    else
    {
        SChatLog(@"No theme data found at path: %@",
                 [pyoncordDirectory URLByAppendingPathComponent:@"current-theme.json"]);
    }

    NSData *fontData = [NSData
        dataWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"fonts.json"]];
    if (fontData)
    {
        NSError      *jsonError;
        NSDictionary *fontDict = [NSJSONSerialization JSONObjectWithData:fontData
                                                                 options:0
                                                                   error:&jsonError];
        if (!jsonError && fontDict[@"main"])
        {
            SChatLog(@"Found font configuration, applying...");
            patchFonts(fontDict[@"main"], fontDict[@"name"]);
        }
    }

    if (bundle)
    {
        SChatLog(@"Executing JS bundle");
        %orig(bundle, source, async);
    }

    NSURL *preloadsDirectory = [pyoncordDirectory URLByAppendingPathComponent:@"preloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:preloadsDirectory.path])
    {
        NSError *error = nil;
        NSArray *contents =
            [[NSFileManager defaultManager] contentsOfDirectoryAtURL:preloadsDirectory
                                          includingPropertiesForKeys:nil
                                                             options:0
                                                               error:&error];
        if (!error)
        {
            for (NSURL *fileURL in contents)
            {
                if ([[fileURL pathExtension] isEqualToString:@"js"])
                {
                    SChatLog(@"Executing preload JS file %@", fileURL.absoluteString);
                    NSData *data = [NSData dataWithContentsOfURL:fileURL];
                    if (data)
                    {
                        %orig(data, source, async);
                    }
                }
            }
        }
        else
        {
            SChatLog(@"Error reading contents of preloads directory");
        }
    }

    %orig(script, url, async);
}

%end

%hook UIWindow

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        isShaking      = YES;
        shakeStartTime = [[NSDate date] timeIntervalSince1970];
    }
    %orig;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && isShaking)
    {
        NSTimeInterval currentTime   = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval shakeDuration = currentTime - shakeStartTime;

        if (shakeDuration >= 0.5 && shakeDuration <= 2.0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{ showSettingsSheet(); });
        }
        isShaking = NO;
    }
    %orig;
}

%end

%ctor
{
    @autoreleasepool
    {
        source = [NSURL URLWithString:@"schat"];

        NSString *install_prefix = @"/var/jb";
        isJailbroken             = [[NSFileManager defaultManager] fileExistsAtPath:install_prefix];

        NSString *bundlePath =
            [NSString stringWithFormat:@"%@/Library/Application Support/SChatResources.bundle",
                                       install_prefix];
        SChatLog(@"Is jailbroken: %d", isJailbroken);
        SChatLog(@"Bundle path for jailbroken: %@", bundlePath);

        NSString *jailedPath = [[NSBundle mainBundle].bundleURL.path
            stringByAppendingPathComponent:@"SChatResources.bundle"];
        SChatLog(@"Bundle path for jailed: %@", jailedPath);

        schatPatchesBundlePath = isJailbroken ? bundlePath : jailedPath;
        SChatLog(@"Selected bundle path: %@", schatPatchesBundlePath);

        BOOL bundleExists =
            [[NSFileManager defaultManager] fileExistsAtPath:schatPatchesBundlePath];
        SChatLog(@"Bundle exists at path: %d", bundleExists);

        NSError *error = nil;
        NSArray *bundleContents =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:schatPatchesBundlePath
                                                                error:&error];
        if (error)
        {
            SChatLog(@"Error listing bundle contents: %@", error);
        }
        else
        {
            SChatLog(@"Bundle contents: %@", bundleContents);
        }

        pyoncordDirectory = getPyoncordDirectory();
        loaderConfig      = [[LoaderConfig alloc] init];
        [loaderConfig loadConfig];

        %init;
    }
}
