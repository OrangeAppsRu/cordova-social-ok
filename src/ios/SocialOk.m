//
//  SocialOk.m

#import "SocialOk.h"

@implementation SocialOk {
    Odnoklassniki *ok;
    void (^okCallBackBlock)(NSString *);
}

@synthesize clientId;

- (void) initSocialOk:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if(!ok) {
        NSString *appId = [[NSString alloc] initWithString:[command.arguments objectAtIndex:0]];
        NSString *secret = [[NSString alloc] initWithString:[command.arguments objectAtIndex:1]];
        NSString *key = [[NSString alloc] initWithString:[command.arguments objectAtIndex:2]];
        ok = [[Odnoklassniki alloc] initWithAppId:appId andAppSecret:secret andAppKey:key andDelegate:self];
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

-(void) share:(CDVInvokedUrlCommand*)command {
    NSString *sourceURL = [command.arguments objectAtIndex:0];
    NSString* description = [command.arguments objectAtIndex:1];
    __block CDVPluginResult* pluginResult = nil;

    if(!ok.session) {
        [self odnoklassnikiLoginWithBlock:^(NSString *token) {
            if(token) {
                [Odnoklassniki requestWithMethodName:@"share.addLink" andParams:@{@"linkUrl": sourceURL, @"comment": description} andHttpMethod:@"GET" andDelegate:self];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                NSLog(@"Cant login to Odnoklassniki");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    } else {
        [Odnoklassniki requestWithMethodName:@"share.addLink" andParams:@{@"linkUrl": sourceURL, @"comment": description} andHttpMethod:@"GET" andDelegate:self];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)odnoklassnikiLoginWithBlock:(void (^)(NSString *))block
{
    [ok authorize:@[@"VALUABLE_ACCESS"]];
    okCallBackBlock = [block copy];
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
    
}

-(void)okDidNotExtendToken:(NSError *)error
{
    
}

-(void)okDidLogout
{
    
}

-(void)request:(OKRequest *)request didLoad:(id)result
{
    NSLog(@"OK Result: %@", result);
}

-(void)request:(OKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"OK Error: %@", error);
}

@end
