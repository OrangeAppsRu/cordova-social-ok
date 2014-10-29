//
//  Created by igor on 17.08.12.
//	Odnoklassniki
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OKRequest.h"

extern NSString* const kLoginURL;
extern NSString* const kRedirectURL;
extern NSString* const kAccessTokenURL;
extern NSString* const kAPIBaseURL;

@protocol OKSessionDelegate<NSObject>
@optional
-(void)okDidLogin;
-(void)okDidNotLogin:(BOOL)canceled;
-(void)okDidNotLoginWithError:(NSError *)error;
-(void)okDidExtendToken:(NSString *)accessToken;
-(void)okDidNotExtendToken:(NSError *)error;
-(void)okDidLogout;
@end

@interface OKSession : NSObject<OKRequestDelegate>

@property(nonatomic, copy) NSString *appId;
@property(nonatomic, strong) NSArray *permissions;
@property(nonatomic, strong) OKRequest *tokenRequest;
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *refreshToken;
@property(nonatomic, weak) id <OKSessionDelegate> delegate;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic, strong) OKRequest *refreshTokenRequest;


+ (OKSession*)activeSession;
+ (OKSession*)setActiveSession:(OKSession*)session;

+ (BOOL)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appID appSecret:(NSString*)secret;

- (id)initWithAppID:(NSString *)appID permissions:(NSArray *)permissions appSecret:(NSString*)secret;
- (void)authorizeWithOKAppAuth:(BOOL)tryOKAppAuth
					safariAuth:(BOOL)trySafariAuth;

- (NSString *)getAppBaseUrl;

- (void)refreshAuthToken;

- (BOOL)handleOpenURL:(NSURL*)url;
- (void)close;

@end