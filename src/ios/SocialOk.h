//
//  SocialOk.h

#import <Cordova/CDV.h>
#import "Odnoklassniki.h"

@interface SocialOk : CDVPlugin <OKSessionDelegate, OKRequestDelegate>
{
    NSString*     clientId;
}

@property (nonatomic, retain) NSString*     clientId;

- (void)initSocialOk:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)share:(CDVInvokedUrlCommand*)command;


@end
