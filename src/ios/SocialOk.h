//
//  SocialOk.h

#import <Cordova/CDV.h>
#import "OKSDK.h"

@interface SocialOk : CDVPlugin
{
    NSString*     clientId;
}

@property (nonatomic, retain) NSString*     clientId;

- (void)initSocialOk:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)share:(CDVInvokedUrlCommand*)command;
- (void)friendsGet:(CDVInvokedUrlCommand*)command;
- (void)friendsGetOnline:(CDVInvokedUrlCommand*)command;
- (void)streamPublish:(CDVInvokedUrlCommand*)command;
- (void)usersGetInfo:(CDVInvokedUrlCommand*)command;
- (void)callApiMethod:(CDVInvokedUrlCommand*)command;
- (void)isOkAppInstalled:(CDVInvokedUrlCommand*)command;

@end
