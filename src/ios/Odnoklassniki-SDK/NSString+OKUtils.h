//
//  NSString+URLParser.h
//  Odnoklassniki iOS example
//
//  Created by Artem Lobachev on 05.05.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OKUtils)

- (NSString*)md5;
- (NSDictionary*)dictionaryByParsingURLQueryPart;
- (NSString*)stringByURLDecodingString;
- (NSString*)URLEncodedString;

@end
