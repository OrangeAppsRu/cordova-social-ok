//
//  Created by igor on 21.08.12.
//	Odnoklassniki
//


#import <Foundation/Foundation.h>

extern NSString *const kOKAccessTokenKey;
extern NSString *const kOKRefreshTokenKey;
extern NSString *const kOKPermissionsKey;

@interface OKTokenCache : NSObject

+(OKTokenCache *)sharedCache;

-(void)cacheTokenInformation:(NSDictionary *)tokenInfo;
-(NSDictionary*)getTokenInformation;
-(void)clearToken;

@end