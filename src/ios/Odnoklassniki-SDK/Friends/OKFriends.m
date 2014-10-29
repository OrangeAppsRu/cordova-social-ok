//
//  Created by igor on 16.11.12.
//	Copyright Odnoklassniki.ru 2012. All rights reserved.
//


#import "OKFriends.h"

#define isValidString(str) str != nil && ![str isEqualToString:@""]

@implementation OKFriends

/**
* Inviting friends to application
* http://dev.odnoklassniki.ru/wiki/display/ok/REST+API+-+friends.appInvite
* @param friendsIds (Required) - array of recipient friend ids
* @param userId - The user ID for the user whose friends you want to return. Specify the uid when calling this method without a session key.
* @param text - Invitation text.
* @param devices - Comma separated list of device groups on which the invitation will be shown. Currently supported groups: IOS, ANDROID, WEB.
*/

+ (void)inviteFriends:(NSArray *)friendsIds forUid:(NSString *)userId invitationText:(NSString *)text devices:(NSString *)devices delegate:(id <OKRequestDelegate>)delegate {
	NSString *userIds = [friendsIds componentsJoinedByString:@","];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:userIds forKey:@"uids"];
	if (isValidString(userId))
		[params setValue:userId forKey:@"uid"];
	if (isValidString(text))
		[params setValue:text forKey:@"text"];
	if (isValidString(devices))
		[params setValue:devices forKey:@"devices"];

	OKRequest *request = [Odnoklassniki requestWithMethodName:@"friends.appInvite" andParams:params andHttpMethod:@"POST" andDelegate:delegate];
	[request load];
}


@end