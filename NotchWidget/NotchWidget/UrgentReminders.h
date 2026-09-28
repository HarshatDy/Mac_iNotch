#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Switches the Reminders app's "Urgent" option on or off for a reminder.
///
/// EventKit has no API for Urgent, so this goes through ReminderKit — Apple's private framework that
/// the Reminders app itself is built on — looked up at runtime. If a future macOS changes it, the
/// call fails with an error instead of crashing.
@interface NTUrgentReminders : NSObject

/// Whether the ReminderKit classes this relies on are present on this macOS.
@property (class, readonly) BOOL isAvailable;

/// `identifier` is the EventKit `calendarItemIdentifier`; `externalIdentifier` is used as a fallback lookup.
+ (BOOL)setUrgent:(BOOL)urgent
    forReminderIdentifier:(NSString *)identifier
       externalIdentifier:(nullable NSString *)externalIdentifier
                    error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
