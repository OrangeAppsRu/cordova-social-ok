//
//  Created by igor on 17.08.12.
//	Odnoklassniki
//


#import "OKSession.h"
#import "OKTokenCache.h"
#import "NSString+OKUtils.h"

NSString* const kLoginURL = @"http://www.odnoklassniki.ru/oauth/authorize";
NSString* const kRedirectURL = @"odnoklassniki://";
NSString* const kAccessTokenURL = @"http://api.odnoklassniki.ru/oauth/token.do";
NSString* const kAPIBaseURL = @"http://api.odnoklassniki.ru/api/";

static NSString *const OKAuthURLScheme = @"okauth";
static NSString *const OKAuthURLPath = @"authorize";

static OKSession *_activeSession = nil;

@interface OKSession()
-(void)didNotLogin:(BOOL)canceled;
-(void)didNotExtendToken:(NSError *)error;
-(void)cacheTokenCahceWithPermissions:(NSDictionary *)tokenInfo;
@end

@implementation OKSession

+ (OKSession *)activeSession {
	if (!_activeSession) {
		OKSession *session = [[OKSession alloc] init];
		[OKSession setActiveSession:session];
	}
	return _activeSession;
}

+ (OKSession *)setActiveSession:(OKSession *)session {
	if (!_activeSession){
		_activeSession = session;
	}else if (session != _activeSession) {
		OKSession *toRelease = _activeSession;
		[toRelease close];
        toRelease = nil;
		_activeSession = session;
	}

	return session;
}

+ (BOOL)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appID appSecret:(NSString*)secret{
	BOOL result = NO;
	OKSession *session = [[OKSession alloc] initWithAppID:appID permissions:permissions appSecret:secret];
	if (session.accessToken != nil) {
		[self setActiveSession:session];
		result = YES;
	}
	return result;
}

- (BOOL)handleOpenURL:(NSURL *)url {
	if (![[url absoluteString] hasPrefix:self.getAppBaseUrl]) {
		NSLog(@"wrong prefix = %@, %@", [url absoluteString], self.getAppBaseUrl);
		return NO;
	}

	NSString *query = [url query];
	NSDictionary *params = [query dictionaryByParsingURLQueryPart];
	if([params valueForKey:@"error"] != nil){
		if ([[params valueForKey:@"error"] isEqualToString:@"access_denied"]){
			[self didNotLogin:YES];
		}else if (self.delegate && [self.delegate respondsToSelector:@selector(okDidNotLoginWithError:)])
			[self.delegate okDidNotLoginWithError:[NSError errorWithDomain:@"Odnoklassniki.ru" code:511 userInfo:params]];
		return YES;
	}

	NSString *code = [params objectForKey:@"code"];

	NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
	[newParams setValue:code forKey:@"code"];
	[newParams setValue:[self.permissions componentsJoinedByString:@","] forKey:@"permissions"];
	[newParams setValue:self.getAppBaseUrl forKey:@"redirect_uri"];
	[newParams setValue:@"authorization_code" forKey:@"grant_type"];
	[newParams setValue:self.appId forKey:@"client_id"];
	[newParams setValue:self.appSecret forKey:@"client_secret"];

	self.tokenRequest = [[OKRequest alloc] init];
	self.tokenRequest.url = [OKRequest serializeURL:kAccessTokenURL params:newParams httpMethod:@"POST"];
	self.tokenRequest.delegate = self;
	self.tokenRequest.params = newParams;
	self.tokenRequest.httpMethod = @"POST";
	[self.tokenRequest load];

	return YES;
}

- (void)close {
	[[OKTokenCache sharedCache] clearToken];
}

- (id)initWithAppID:(NSString *)appID permissions:(NSArray *)permissions appSecret:(NSString*)secret {
	self = [super init];
	if (self){
		self.appId = appID;
		self.permissions = permissions;
		self.appSecret = secret;

		//[[OKTokenCache sharedCache] clearToken];

		NSDictionary *cachedToken = [[OKTokenCache sharedCache] getTokenInformation];
		if(cachedToken){
			self.accessToken = [cachedToken valueForKey:kOKAccessTokenKey];
			self.refreshToken = [NSString stringWithFormat:@"%@", [cachedToken valueForKey:kOKRefreshTokenKey]];
			NSArray *aPermissions = [cachedToken valueForKey:kOKPermissionsKey];

			if (self.permissions == nil) self.permissions = aPermissions;

			if (![self.permissions isEqualToArray:aPermissions]){
				self.accessToken = nil;
				self.refreshToken = nil;
			}
		}
	}
    return self;
}

- (void)authorizeWithOKAppAuth:(BOOL)tryOKAppAuth
					safariAuth:(BOOL)trySafariAuth {

	if(self.accessToken){
		if (self.delegate && [self.delegate respondsToSelector:@selector(okDidLogin)])
			[self.delegate okDidLogin];
		return;
	}

	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			self.appId, @"client_id",
			[self getAppBaseUrl], @"redirect_uri",
			@"code", @"response_type",
			nil];

	NSString *loginURL = kLoginURL;

	if (self.permissions){
		NSString *scope = [self.permissions componentsJoinedByString:@";"];
		[params setValue:scope forKey:@"scope"];
	}

	BOOL didAuthNWithOKApp = NO;

	if (tryOKAppAuth){
		NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", OKAuthURLScheme, OKAuthURLPath];
		NSString *okAppUrl = [OKRequest serializeURL:urlPrefix params:params];
		didAuthNWithOKApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:okAppUrl]];
	}
	if (trySafariAuth && !didAuthNWithOKApp) {
        [params setValue:@"m" forKey:@"layout"];
		NSString *okAppUrl = [OKRequest serializeURL:loginURL params:params];
		NSLog(@"OK app url = %@", okAppUrl);
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:okAppUrl]];
	}
}

- (NSString *)getAppBaseUrl {
	return [NSString stringWithFormat:@"ok%@%@://authorize",
									  self.appId,
									  @""];
}

-(void)refreshAuthToken {
	NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
	[newParams setValue:self.refreshToken forKey:@"refresh_token"];
	[newParams setValue:@"refresh_token" forKey:@"grant_type"];
	[newParams setValue:self.appId forKey:@"client_id"];
	[newParams setValue:self.appSecret forKey:@"client_secret"];

	self.refreshTokenRequest = [[OKRequest alloc] init];
	self.refreshTokenRequest.url = [OKRequest serializeURL:kAccessTokenURL params:newParams httpMethod:@"POST"];
	self.refreshTokenRequest.delegate = self;
	self.refreshTokenRequest.params = newParams;
	self.refreshTokenRequest.httpMethod = @"POST";
	[self.refreshTokenRequest load];
}

-(void)cacheTokenCahceWithPermissions:(NSDictionary *)tokenInfo {
	NSMutableDictionary *dct = [NSMutableDictionary dictionaryWithDictionary:tokenInfo];
	[dct setValue:self.permissions forKey:kOKPermissionsKey];
	[[OKTokenCache sharedCache] cacheTokenInformation:dct];
}

-(void)didNotLogin:(BOOL)canceled {
	if (self.delegate && [self.delegate respondsToSelector:@selector(okDidNotLogin:)])
		[self.delegate okDidNotLogin:canceled];
}

-(void)didNotExtendToken:(NSError *)error {
	if(self.delegate && [self.delegate respondsToSelector:@selector(okDidNotExtendToken:)])
		[self.delegate okDidNotExtendToken:error];
}

/*** OKAPIRequest delegate only for authorization ***/
-(void)request:(OKRequest *)request didLoad:(id)result {
	if (request == self.tokenRequest){
		if (request.hasError){
			[self didNotLogin:NO];
			return;
		}
		[self cacheTokenCahceWithPermissions:result];
		self.accessToken = [(NSDictionary *)result valueForKey:kOKAccessTokenKey];
		self.refreshToken = [(NSDictionary *)result valueForKey:kOKRefreshTokenKey];

		if (self.delegate && [self.delegate respondsToSelector:@selector(okDidLogin)])
			[self.delegate okDidLogin];

	}else if(request == self.refreshTokenRequest){
		if (self.refreshTokenRequest.hasError){
			[self didNotExtendToken:nil];
			return;
		}

		NSMutableDictionary *dct = [NSMutableDictionary dictionaryWithDictionary:[[OKTokenCache sharedCache] getTokenInformation]];
		self.accessToken = [(NSDictionary *)result valueForKey:kOKAccessTokenKey];
		[dct setValue:self.accessToken forKey:kOKAccessTokenKey];
		[self cacheTokenCahceWithPermissions:dct];
		if (self.delegate && [self.delegate respondsToSelector:@selector(okDidExtendToken:)])
			[self.delegate okDidExtendToken:self.accessToken];
	}
}

-(void)request:(OKRequest *)request didFailWithError:(NSError *)error {
	if (request == self.tokenRequest){
		if (request.sessionExpired){
			[self refreshAuthToken];
		}else
			[self didNotLogin:NO];
	} else if(request == self.refreshTokenRequest){
		[self didNotExtendToken:error];
	}
}

@end