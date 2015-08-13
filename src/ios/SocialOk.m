//
//  SocialOk.m

#import "SocialOk.h"
#import "OKMediaTopicPostViewController.h"

@implementation SocialOk {
    Odnoklassniki *ok;
    void (^okCallBackBlock)(NSString *);
    CDVInvokedUrlCommand *savedCommand;
}

@synthesize clientId;

- (void) initSocialOk:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if(!ok) {
        NSString *appId = [[NSString alloc] initWithString:[command.arguments objectAtIndex:0]];
        NSString *secret = [[NSString alloc] initWithString:[command.arguments objectAtIndex:1]];
        NSString *key = [[NSString alloc] initWithString:[command.arguments objectAtIndex:2]];
        ok = [[Odnoklassniki alloc] initWithAppId:appId appSecret:secret appKey:key delegate:self];
        NSLog(@"SocialOk Plugin initalized");
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myOpenUrl:) name:CDVPluginHandleOpenURLNotification object:nil];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)myOpenUrl:(NSNotification*)notification
{
    NSURL *url = notification.object;
    if(![url isKindOfClass:NSURL.class]) return;
    [ok.session handleOpenURL:url];
}

#pragma mark - API Methods

-(void) login:(CDVInvokedUrlCommand *)command
{
    __block CDVPluginResult* pluginResult = nil;
    NSArray *permissions = nil;
    if(command.arguments.count > 0 && [command.arguments.firstObject isKindOfClass:NSArray.class])
        permissions = command.arguments.firstObject;
    if(!ok.session) {
        [self odnoklassnikiLoginWithPermissions:permissions andBlock:^(NSString *token) {
            if(token) {
                OKRequest * req = [Odnoklassniki requestWithMethodName:@"users.getCurrentUser" params:nil];
                [req executeWithCompletionBlock:^(id data) {
                    NSDictionary *loginResult = @{@"user": data, @"token": token};
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:loginResult];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } errorBlock:^(NSError *error) {
                    NSLog(@"Cant login to Odnoklassniki");
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }];
            } else {
                NSLog(@"Cant login to Odnoklassniki");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    } else {
        if(OKSession.activeSession && OKSession.activeSession.accessToken) {
            OKRequest * req = [Odnoklassniki requestWithMethodName:@"users.getCurrentUser" params:nil];
            [req executeWithCompletionBlock:^(id data) {
                NSDictionary *loginResult = @{@"user": data, @"token": OKSession.activeSession.accessToken};
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:loginResult];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } errorBlock:^(NSError *error) {
                NSLog(@"Cant login to Odnoklassniki");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
        } else {
            NSLog(@"Cant login to Odnoklassniki");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
}

-(void) share:(CDVInvokedUrlCommand*)command {
    savedCommand = command;
    NSString *sourceURL = [command.arguments objectAtIndex:0];
    NSString* description = [command.arguments objectAtIndex:1];

    __block CDVPluginResult* pluginResult = nil;
    if(!ok.session) {
        [self odnoklassnikiLoginWithPermissions:nil andBlock:^(NSString *token) {
            if(token) {
                OKRequest * req = [Odnoklassniki requestWithMethodName:@"share.addLink" params:@{@"linkUrl": sourceURL, @"comment": description} httpMethod:@"GET" delegate:self];
                [req load];
            } else {
                NSLog(@"Cant login to Odnoklassniki");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    } else {
        OKRequest* req = [Odnoklassniki requestWithMethodName:@"share.addLink" params:@{@"linkUrl": sourceURL, @"comment": description} httpMethod:@"GET" delegate:self];
        [req load];
    }
}

- (void)friendsGet:(CDVInvokedUrlCommand*)command
{
    NSString *fid = [command.arguments objectAtIndex:0];
    NSString *sort_type = [command.arguments objectAtIndex:1];
    OKRequest *req = [Odnoklassniki requestWithMethodName:@"friends.get" params:@{@"fid": fid, @"sort_type": sort_type}];
    [self performRequest:req withCommand:command];
}

- (void)friendsGetOnline:(CDVInvokedUrlCommand*)command
{
    NSString *uid = [command.arguments objectAtIndex:0];
    NSString *online = [command.arguments objectAtIndex:1];
    OKRequest *req = [Odnoklassniki requestWithMethodName:@"friends.getOnline" params:@{@"uid": uid, @"online": online}];
    [self performRequest:req withCommand:command];
}

- (void)streamPublish:(CDVInvokedUrlCommand*)command
{
    NSDictionary *attachments = [command.arguments objectAtIndex:0];
    OKMediaTopicPostViewController *vc = [OKMediaTopicPostViewController postViewControllerWithAttachments:attachments];
    [vc presentInViewController:UIApplication.sharedApplication.keyWindow.rootViewController];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)usersGetInfo:(CDVInvokedUrlCommand*)command
{
    NSString *uids = [command.arguments objectAtIndex:0];
    NSString *fields = [command.arguments objectAtIndex:1];
    OKRequest *req = [Odnoklassniki requestWithMethodName:@"users.getInfo" params:@{@"uids": uids, @"fields": fields}];
    [self performRequest:req withCommand:command];
}

-(void)callApiMethod:(CDVInvokedUrlCommand *)command
{
    NSString *method = [command.arguments objectAtIndex:0];
    NSDictionary *params = [command.arguments objectAtIndex:1];
    OKRequest *req = [Odnoklassniki requestWithMethodName:method params:params];
    [self performRequest:req withCommand:command];
}

-(void)performRequest:(OKRequest*)req withCommand:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    [req executeWithCompletionBlock:^(id data) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } errorBlock:^(NSError *error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

#pragma mark - Utils & Delegate

-(void)odnoklassnikiLoginWithPermissions:(NSArray*)permissions andBlock:(void (^)(NSString *))block
{
    okCallBackBlock = [block copy];
    if(!permissions) permissions = @[@"VALUABLE_ACCESS"];
    [ok authorizeWithPermissions:permissions];
}

- (void)okShouldPresentAuthorizeController:(UIViewController *)viewController
{
    NSLog(@"okShouldPresentAuthorizeController");
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
}

-(void)okDidLogin
{
    NSLog(@"OK Token %@", OKSession.activeSession.accessToken);
    if(okCallBackBlock) okCallBackBlock(OKSession.activeSession.accessToken);
}

-(void)okDidNotLogin:(BOOL)canceled
{
    if(okCallBackBlock) okCallBackBlock(nil);
}

-(void)okDidExtendToken:(NSString *)accessToken
{
    NSLog(@"OK did extend token: %@", accessToken);
}

-(void)okDidNotExtendToken:(NSError *)error
{
    NSLog(@"Did not extend OK token: %@", error);
}

-(void)okDidLogout
{
    NSLog(@"OK did logout");
}



-(void)request:(OKRequest *)request didLoad:(id)result
{
    NSLog(@"OK Result: %@", result);
    if(savedCommand) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:savedCommand.callbackId];
        savedCommand = nil;
    }
}

-(void)request:(OKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"OK Error: %@", error);
    if(error.code == 102) {
        [ok.session refreshAuthToken];
    }
    if(savedCommand) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:savedCommand.callbackId];
        savedCommand = nil;
    }
}

@end
