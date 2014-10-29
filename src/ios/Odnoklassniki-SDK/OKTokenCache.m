//
//  Created by igor on 21.08.12.
//	Odnoklassniki
//


#import "OKTokenCache.h"


static NSString *const OKTokenKey = @"ru.odnoklassniki.sdk:TokenKey";

NSString *const kOKAccessTokenKey = @"access_token";
NSString *const kOKRefreshTokenKey = @"refresh_token";
NSString *const kOKPermissionsKey = @"permissions";

static OKTokenCache *sharedInstance;

@implementation OKTokenCache

+(OKTokenCache *)sharedCache {
	@synchronized(self)
	{
		if(sharedInstance == NULL) {
			sharedInstance = [[OKTokenCache alloc] init];
		}
	}
	return sharedInstance;
}

-(void)cacheTokenInformation:(NSDictionary *)tokenInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:tokenInfo forKey:OKTokenKey];
	[defaults synchronize];
}

-(NSDictionary *)getTokenInformation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:OKTokenKey];
}

-(void)clearToken {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:OKTokenKey];
	[defaults synchronize];
}

@end