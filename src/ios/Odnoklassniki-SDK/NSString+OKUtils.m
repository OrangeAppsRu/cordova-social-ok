//
//  NSString+URLParser.m
//  Odnoklassniki iOS example
//
//  Created by Artem Lobachev on 05.05.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import "NSString+OKUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (OKUtils)

- (NSString*)md5{
	const char *cStr = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
    
	CC_MD5( cStr, strlen(cStr), result );
    
	return [NSString
			stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],
            result[2],  result[3],
            result[4],  result[5],
            result[6],  result[7],
            result[8],  result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]
            ];
}

- (NSDictionary*)dictionaryByParsingURLQueryPart {
    
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSArray *parts = [self componentsSeparatedByString:@"&"];
    
	for (NSString *part in parts) {
		if ([part length] == 0) {
			continue;
		}
        
		NSRange index = [part rangeOfString:@"="];
		NSString *key;
		NSString *value;
        
		if (index.location == NSNotFound) {
			key = part;
			value = @"";
		} else {
			key = [part substringToIndex:index.location];
			value = [part substringFromIndex:index.location + index.length];
		}
        
		if (key && value) {
			[result setObject:[value stringByURLDecodingString]
                       forKey:[key stringByURLDecodingString]];
		}
	}
	return result;
}

// the reverse of url encoding
- (NSString*)stringByURLDecodingString {
	return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "]
			stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)URLEncodedString {
	NSString* result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                             kCFAllocatorDefault,
                                                                                             (CFStringRef)self,
                                                                                             NULL, // characters to leave unescaped
                                                                                             (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                                             kCFStringEncodingUTF8));
	return result;
}

@end
