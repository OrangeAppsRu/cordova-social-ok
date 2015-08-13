//
//  SocialOk.m

#import "SocialOk.h"

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

-(void) login:(CDVInvokedUrlCommand *)command
{
    __block CDVPluginResult* pluginResult = nil;
    if(!ok.session) {
        [self odnoklassnikiLoginWithBlock:^(NSString *token) {
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
        [self odnoklassnikiLoginWithBlock:^(NSString *token) {
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

-(void)odnoklassnikiLoginWithBlock:(void (^)(NSString *))block
{
    okCallBackBlock = [block copy];
    [ok authorizeWithPermissions:@[@"VALUABLE_ACCESS"]];
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
