//
//  Created by igor on 16.08.12.
//	Odnoklassniki
//


#import "OKRequest.h"
#import "OKSession.h"
#import "NSString+OKUtils.h"

static const NSTimeInterval kRequestTimeoutInterval = 180.0;
static NSString* kUserAgent = @"OdnoklassnikiIOs";

@interface OKRequest()
+ (NSString *)getSignatureForParams:(NSDictionary *)params
					withAccessToken:(NSString *)accessToken
						  andSecret:(NSString *)secret;

- (void)handleResponse:(NSMutableData *)data;

- (void)failWithError:(NSError *)error;

- (id)formatError:(NSInteger)code userInfo:(NSDictionary *)errorData;

@end

@implementation OKRequest

+ (NSString*)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params
			   httpMethod:(NSString *)httpMethod{
	NSURL* parsedURL = [NSURL URLWithString:baseUrl];
	NSString* queryPrefix = parsedURL.query ? @"&" : @"?";

	NSMutableArray* pairs = [NSMutableArray array];
	for (NSString* key in [params keyEnumerator]) {
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [[params objectForKey:key]URLEncodedString]]];
	}
	NSString* query = [pairs componentsJoinedByString:@"&"];

	return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

+ (NSString*)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params{
	return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}

+ (NSString *)getSignatureForParams:(NSDictionary *)params withAccessToken:(NSString *)accessToken andSecret:(NSString *)secret{
	NSArray *sortedKeys = [[params allKeys] sortedArrayUsingSelector: @selector(compare:)];
	NSMutableString *signatureString = [NSMutableString stringWithString:@""];
	for (int i =0; i<sortedKeys.count; i++){
		NSString *key = [sortedKeys objectAtIndex:i];
		[signatureString appendString:[NSString stringWithFormat:@"%@=%@", key, [params valueForKey:key]]];
	}

	[signatureString appendString:[[NSString stringWithFormat:@"%@%@", accessToken, secret]md5]];
	return [[signatureString md5] lowercaseString];
}

+ (OKRequest*)getRequestWithParams:(NSMutableDictionary *) params
						httpMethod:(NSString *) httpMethod
						  delegate:(id<OKRequestDelegate>)delegate
						 apiMethod:(NSString *)apiMethod{
	OKRequest *request = [[OKRequest alloc] init];
	request.delegate = delegate;
	request.params = params;

	NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
	[newParams setValue:[OKSession activeSession].appKey forKey:@"application_key"];

	NSString *signature = [OKRequest getSignatureForParams:newParams withAccessToken:[OKSession activeSession].accessToken andSecret:[OKSession activeSession].appSecret];
	[newParams setValue:signature forKey:@"sig"];
	[newParams setValue:[OKSession activeSession].accessToken forKey:@"access_token"];

	NSString *method = [apiMethod stringByReplacingOccurrencesOfString:@"." withString:@"/"];

	request.url = [OKRequest serializeURL:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, method] params:newParams httpMethod:httpMethod];
	request.httpMethod = httpMethod;
	return request;
}

-(void)load {
	self.responseText = [[NSMutableData alloc] init];

	NSURL *url = [NSURL URLWithString:self.url];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
													   timeoutInterval:kRequestTimeoutInterval];
	request.HTTPMethod = self.httpMethod ? self.httpMethod : @"GET";
	[request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
	self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)handleResponse:(NSMutableData *)data {
	id result;
    NSError *jsonParsingError = nil;
    result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
	NSInteger error_code = [self checkResponseForErrorCodes:result];

	if(error_code == PARAM_SESSION_EXPIRED){
		self.sessionExpired = YES;
	}

	if(error_code>0){
		[self failWithError:[self formatError:error_code userInfo:result]];
		return;
	}

	if (self.delegate && [self.delegate respondsToSelector:@selector(request:didLoad:)])
		[self.delegate request:self didLoad:result];
}

-(void)failWithError:(NSError *)error{
	if (self.delegate && [self.delegate respondsToSelector:@selector(request:didFailWithError:)])
		[self.delegate request:self didFailWithError:error];
}

- (id)formatError:(NSInteger)code userInfo:(NSDictionary *) errorData {
	return [NSError errorWithDomain:@"OdnoklassnikiErrDomain" code:code userInfo:errorData];

}

-(NSInteger)checkResponseForErrorCodes:(id)data {
	if(data == nil) return 0;

	if([data isKindOfClass:[NSArray class]]) return 0;
	if (![data isKindOfClass:[NSDictionary class]]) return 0;

	if([data valueForKey:@"error_code"] != nil){

		NSInteger code = [[data valueForKey:@"error_code"] intValue];

		return code;
	}
	return 0;
}



/**
* NSURLConnection Delegate
*/

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseText appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self handleResponse:self.responseText];

	self.responseText = nil;
	self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self failWithError:error];

	self.responseText = nil;
	self.connection = nil;
}

@end