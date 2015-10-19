//
//  SocialOk.m

#import "SocialOk.h"

@implementation SocialOk {
    void (^okCallBackBlock)(NSString *, NSString *);
    CDVInvokedUrlCommand *savedCommand;
}

@synthesize clientId;

- (void) initSocialOk:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    NSString *appId = [[NSString alloc] initWithString:[command.arguments objectAtIndex:0]];
    NSString *key = [[NSString alloc] initWithString:[command.arguments objectAtIndex:2]];
    [OKSDK initWithAppIdAndAppKey:[NSNumber numberWithInteger:[appId integerValue]] appKey:key];
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

-(void) login:(CDVInvokedUrlCommand *)command
{
    __block CDVPluginResult* pluginResult = nil;
    NSArray *permissions = nil;
    if(command.arguments.count > 0 && [command.arguments.firstObject isKindOfClass:NSArray.class])
        permissions = command.arguments.firstObject;
    [OKSDK authorizeWithPermissions:permissions success:^(NSString *token) {
        [OKSDK invokeMethod:@"users.getCurrentUser" arguments:nil success:^(id data) {
            NSDictionary *loginResult = @{@"user": data, @"token": token};
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:loginResult];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } error:^(NSError *error) {
            if(error.code == 102 || error.code == 103) {
                // session expired or invalid session key
                NSLog(@"OK Session expired. Try to logout and login again.");
                //ok.logout;
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

-(void)performRequest:(NSString*)method withParams:(NSDictionary*)arguments andCommand:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    [OKSDK invokeMethod:method arguments:arguments success:^(id data) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } error:^(NSError *error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

#pragma mark - Utils & Delegate

-(void)OKSDKLoginWithPermissions:(NSArray*)permissions andBlock:(void (^)(NSString *, NSString *))block
{
    okCallBackBlock = [block copy];
    if(!permissions) permissions = @[@"VALUABLE ACCESS"];
    [OKSDK authorizeWithPermissions:permissions success:^(id data) {
        NSLog(@"OK Token %@", data[@"session_key"]);
        if(okCallBackBlock) okCallBackBlock(data[@"session_key"], nil);
    } error:^(NSError *error) {
        if(okCallBackBlock) okCallBackBlock(nil, error.description);
    }];
}

@end
