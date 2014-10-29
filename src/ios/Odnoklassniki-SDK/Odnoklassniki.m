//
//  Created by igor on 14.08.12.
//	Odnoklassniki
//


#import "Odnoklassniki.h"

@implementation Odnoklassniki

/**
* Initializes Odnoklassniki object
* @param anAppId application ID
* @param anAppSecret application SECRET
* @param anAppKey application KEY
* @param aDelegate OKSessionDelegate
*/
-(id)initWithAppId:(NSString *)anAppId
	  andAppSecret:(NSString *)anAppSecret
		 andAppKey:(NSString *)anAppKey
	   andDelegate:(id<OKSessionDelegate>)aDelegate{

	self = [super init];
	if (self){
		self.appId = anAppId;
		self.appSecret = anAppSecret;
		self.appKey = anAppKey;
		self.delegate = aDelegate;
	}
	return self;
}

/**
* Authorize the application with permissions
* @param permissions comma-separated permissions scope (VALUABLE ACCESS, SET STATUS, PHOTO CONTENT)
*/
- (void)authorize:(NSArray *)permissions {
	[self.session close];
	self.session = [[OKSession alloc] initWithAppID:self.appId permissions:permissions appSecret:self.appSecret];
	self.session.delegate = self.delegate;
	self.session.appKey = self.appKey;
	[OKSession setActiveSession:self.session];
	[self.session authorizeWithOKAppAuth:YES safariAuth:YES];
}

/**
* Refresh token if session has expired
*/
-(void)refreshToken {
    self.session.delegate = self.delegate;
	[self.session refreshAuthToken];
}

/**
* Invalidate the current user session by removing the access token in memory
* and calls OKSessionDelegate's method okDidLogout
*/
-(void)logout {
	[self.session close];
	[OKSession setActiveSession:nil];
	self.session = nil;

	if (self.delegate && [self.delegate respondsToSelector:@selector(okDidLogout)])
		[self.delegate okDidLogout];
}

/**
 * @return boolean - whether this object has an non-expired session token
 */
-(BOOL)isSessionValid {
	if(!self.session){
		BOOL active_session_opened = [OKSession openActiveSessionWithPermissions:nil appId:self.appId appSecret:self.appSecret];
		if (active_session_opened)
			self.session = [OKSession activeSession];
			self.session.appKey = self.appKey;
	}
	return self.session != nil && self.session.accessToken != nil;
}

/**
 * Make a request to Odnoklassniki's REST API with the given method name and parameters.
 * @param methodName REST server API method (list of methods http://dev.odnoklassniki.ru/wiki/display/ok/Odnoklassniki+Rest+API).
 * @param params Key-value pairs of parameters to the request.
 * @param delegate Callback interface for notifying the calling application when the request has received response.
 * @return OKRequest Returns a pointer to the OKRequest object.
*/
+(OKRequest *)requestWithMethodName:(NSString *)methodName
						  andParams:(NSMutableDictionary *)params
					  andHttpMethod:(NSString *)httpMethod
						andDelegate:(id <OKRequestDelegate>)delegate {
	return [OKRequest getRequestWithParams:params httpMethod:httpMethod delegate:delegate apiMethod:methodName];
}

- (void)dealloc {
	[self.session close];
	[OKSession setActiveSession:nil];
}

@end