//
//  BatchPush.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @enum BatchNotificationType
 @abstract Remote notification types wrapper.
 @discussion Wrap iOS 8 and inferior remote notification types.
 */
typedef NS_OPTIONS(NSUInteger, BatchNotificationType)
{
    BatchNotificationTypeNone    = 0,
    BatchNotificationTypeBadge   = 1 << 0,
    BatchNotificationTypeSound   = 1 << 1,
    BatchNotificationTypeAlert   = 1 << 2,
};

/*!
 @class BatchPush
 @abstract Provides the Batch-related Push methods
 @discussion Actions you can perform in BatchPush.
 */
@interface BatchPush : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
@method setRemoteNotificationTypes:
@abstract Change the used remote notification types.
@discussion Default value is: BatchNotificationTypeBadge | BatchNotificationTypeSound | BatchNotificationTypeAlert
@param type : A bit mask specifying the types of notifications the app accepts.
*/
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type NS_AVAILABLE_IOS(6_0);

/*!
 @method registerForRemoteNotifications
 @abstract Call to trigger the iOS popup that asks the user if he wants to allow Push Notifications and register to APNS.
 @discussion Default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 @discussion You should call this at a strategic moment, like at the end of your welcome.
 */
+ (void)registerForRemoteNotifications NS_AVAILABLE_IOS(6_0);

/*!
 @method registerForRemoteNotificationsWithCategories:
 @abstract Call to trigger the iOS popup that asks the user if he wants to allow Push Notifications and register to APNS.
 @discussion Default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 @discussion You should call this at a strategic moment, like at the end of your welcome.
 @param categories  : A set of UIUserNotificationCategory objects that define the groups of actions a notification may include.
 */
+ (void)registerForRemoteNotificationsWithCategories:(NSSet *)categories NS_AVAILABLE_IOS(8_0);

/*!
 @method clearBadge
 @abstract Clear the application's badge on the homescreen.
 @discussion You do not need to call this if you already call dismissNotifications.
 */
+ (void)clearBadge NS_AVAILABLE_IOS(6_0);

/*!
 @method dismissNotifications
 @abstract Clear the app's notifications in the notification center. Also clears your badge.
 @discussion Call this when you want to remove the notifications. Your badge is removed afterwards, so if you want one, you need to set it up again.
 */
+ (void)dismissNotifications NS_AVAILABLE_IOS(6_0);

@end
