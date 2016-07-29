//
//  SocialOk.m

#import "SocialOk.h"

NSString* COPY_OK_OAUTH_APP_URL = @"okauth://authorize";

@implementation SocialOk {
    void (^okCallBackBlock)(NSString *, NSString *);
    CDVInvokedUrlCommand *savedCommand;
}

@synthesize clientId;

#pragma mark - Plugin interface

-(UIViewController*)findViewController
{
    id vc = self.webView;
    do {
        vc = [vc nextResponder];
    } while([vc isKindOfClass:UIView.class]);
    return vc;
}

- (void) initSocialOk:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    NSString *appId = [[NSString alloc] initWithString:[command.arguments objectAtIndex:0]];
    NSString *key = [[NSString alloc] initWithString:[command.arguments objectAtIndex:1]];
    OKSDKInitSettings *settings = [OKSDKInitSettings new];
    settings.appId = appId;
    settings.appKey = key;
    settings.controllerHandler = ^UIViewController*() {
        return [self findViewController];
    };
    [OKSDK initWithSettings:settings];
    NSLog(@"SocialOk Plugin initalized");
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myOpenUrl:) name:CDVPluginHandleOpenURLNotification object:nil];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)myOpenUrl:(NSNotification*)notification
{
    NSURL *url = notification.object;
    if(![url isKindOfClass:NSURL.class]) return;
    [OKSDK openUrl:url];
}

-(void)fail:(NSString*)error command:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - API Methods

-(void)isOkAppInstalled:(CDVInvokedUrlCommand *)command
{
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *appUrl = [NSURL URLWithString:COPY_OK_OAUTH_APP_URL];
    CDVPluginResult* pluginResult;
    if ([app canOpenURL: appUrl]) {
        // yes
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
    } else {
        // no
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"false"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) login:(CDVInvokedUrlCommand *)command
{
    __block CDVPluginResult* pluginResult = nil;
    NSArray *permissions = nil;
    if(command.arguments.count > 0) {
        id prm = command.arguments.firstObject;
        if([prm isKindOfClass:NSArray.class]) {
            permissions = command.arguments.firstObject;
        } else if([prm isKindOfClass:NSString.class]) {
            permissions = [prm componentsSeparatedByString:@","];
        } else {
            permissions = @[];
        }
    }
    [OKSDK authorizeWithPermissions:permissions success:^(NSArray *tokenAndSecret) {
        NSString *token = @"", *secretKey = @"";
        if(tokenAndSecret.count > 0) token = tokenAndSecret[0];
        if(tokenAndSecret.count > 1) secretKey = tokenAndSecret[1];
        [OKSDK invokeMethod:@"users.getCurrentUser" arguments:nil success:^(id data) {
            NSDictionary *loginResult = @{@"user": data, @"token": token, @"session_secret_key": secretKey};
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:loginResult];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } error:^(NSError *error) {
            if(error.code == 102 || error.code == 103) {
                // session expired or invalid session key
                NSLog(@"OK Session expired. Try to logout and login again.");
                [OKSDK clearAuth];
                [self login:command];
                return;
            }
            NSLog(@"Cant login to OKSDK");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    } error:^(NSError *error) {
        NSLog(@"Cant login to OKSDK");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

-(void) share:(CDVInvokedUrlCommand*)command {
    savedCommand = command;
    NSString *sourceURL = [command.arguments objectAtIndex:0];
    NSString* description = [command.arguments objectAtIndex:1];

    __block CDVPluginResult* pluginResult = nil;
    [OKSDK invokeMethod:@"share.addLink" arguments:@{@"linkUrl": sourceURL, @"comment": description} success:^(id data) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } error:^(NSError *error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)friendsGet:(CDVInvokedUrlCommand*)command
{
    NSString *fid = [command.arguments objectAtIndex:0];
    NSString *sort_type = [command.arguments objectAtIndex:1];
    @try {
        [self performRequest:@"friends.get" withParams:@{@"fid": fid, @"sort_type": sort_type} andCommand:command];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

- (void)friendsGetOnline:(CDVInvokedUrlCommand*)command
{
    NSString *uid = [command.arguments objectAtIndex:0];
    NSString *online = [command.arguments objectAtIndex:1];
    @try {
        [self performRequest:@"friends.getOnline" withParams:@{@"uid": uid, @"online": online} andCommand:command];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

- (void)streamPublish:(CDVInvokedUrlCommand*)command
{
    /*
    NSDictionary *attachments = [command.arguments objectAtIndex:0];
    OKMediaTopicPostViewController *vc = [OKMediaTopicPostViewController postViewControllerWithAttachments:attachments];
    [vc presentInViewController:UIApplication.sharedApplication.keyWindow.rootViewController];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     */
}

- (void)usersGetInfo:(CDVInvokedUrlCommand*)command
{
    NSString *uids = [command.arguments objectAtIndex:0];
    NSString *fields = [command.arguments objectAtIndex:1];
    @try {
        [self performRequest:@"users.getInfo" withParams:@{@"uids": uids, @"fields": fields} andCommand:command];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

- (void)reportPayment:(CDVInvokedUrlCommand*)command
{
    NSString *trx_id = [command.arguments objectAtIndex:0];
    NSString *amount = [command.arguments objectAtIndex:1];
    NSString *currency = [command.arguments objectAtIndex:2];
    @try {
        [self performRequest:@"sdk.reportPayment" withParams:@{@"trx_id": trx_id, @"amount": amount, @"currency": currency} andCommand:command];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

- (void)getInstallSource:(CDVInvokedUrlCommand*)command
{
    @try {
        [OKSDK getInstallSource:^(NSNumber* data) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[data intValue]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } error:^(NSError *error) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

- (void)performPosting:(CDVInvokedUrlCommand*)command
{
    NSDictionary *params = [command.arguments objectAtIndex:0];
    [self performSdkRequest:@"sdk.post" withParams:params andCommand:command];
}

- (void)performSuggest:(CDVInvokedUrlCommand*)command
{
    NSDictionary *params = [command.arguments objectAtIndex:0];
    [self performSdkRequest:@"sdk.appSuggest" withParams:params andCommand:command];
}

- (void)performInvite:(CDVInvokedUrlCommand*)command
{
    NSDictionary *params = [command.arguments objectAtIndex:0];
    [self performSdkRequest:@"sdk.appInvite" withParams:params andCommand:command];
}

- (void)reportStats:(CDVInvokedUrlCommand*)command
{
    NSDictionary *params = [command.arguments objectAtIndex:0];
    [self performSdkRequest:@"sdk.reportStats" withParams:params andCommand:command];
}

-(void)callApiMethod:(CDVInvokedUrlCommand *)command
{
    NSString *method = [command.arguments objectAtIndex:0];
    NSDictionary *params = [command.arguments objectAtIndex:1];
    @try {
        [self performRequest:method withParams:params andCommand:command];
    } @catch (NSException *e) {
        [self fail:@"Invalid request" command:command];
    }
}

#pragma mark - OK SDK API functions

-(void)performRequest:(NSString*)method withParams:(NSDictionary*)arguments andCommand:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    [OKSDK invokeMethod:method arguments:arguments success:^(id data) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } error:^(NSError *error) {
        if(error.code == 10) {
            // PERMISSION_DENIED
            // try to clear auth cache for next login
            [OKSDK clearAuth];
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

-(void)performSdkRequest:(NSString*)method withParams:(NSDictionary*)arguments andCommand:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    [OKSDK invokeMethod:method arguments:arguments success:^(id data) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } error:^(NSError *error) {
        if(error.code == 10) {
            // PERMISSION_DENIED
            // try to clear auth cache for next login
            [OKSDK clearAuth];
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


@end
