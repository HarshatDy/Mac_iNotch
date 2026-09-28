#import "UrgentReminders.h"
#import <dlfcn.h>

// Just enough of ReminderKit's (private) interface to flip the Urgent switch.

@protocol NTRemStore <NSObject>
- (nullable id)fetchReminderWithObjectID:(id)objectID error:(NSError **)error;
- (nullable NSArray *)fetchAllRemindersWithExternalIdentifier:(NSString *)externalIdentifier error:(NSError **)error;
@end

@protocol NTRemReminderClass <NSObject>
- (id)objectIDWithUUID:(NSUUID *)uuid;     // class method on REMReminder
@end

@protocol NTRemReminder <NSObject>
- (nullable id)urgentAlarmContext;
@end

@protocol NTRemSaveRequest <NSObject>
- (instancetype)initWithStore:(id)store;
- (nullable id)updateReminder:(id)reminder;
- (BOOL)saveSynchronouslyWithError:(NSError **)error;
@end

@protocol NTRemUrgentContext <NSObject>
- (BOOL)isUrgentStateEnabledForCurrentUser;
- (void)setIsUrgentStateEnabledForCurrentUser:(BOOL)enabled;
@end

static NSString * const NTUrgentErrorDomain = @"NotcheeeUrgentReminders";

static NSError *NTError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:NTUrgentErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

@implementation NTUrgentReminders

+ (BOOL)isAvailable {
    static BOOL available;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dlopen("/System/Library/PrivateFrameworks/ReminderKit.framework/ReminderKit", RTLD_NOW);
        available = NSClassFromString(@"REMStore") != nil
                 && NSClassFromString(@"REMSaveRequest") != nil
                 && NSClassFromString(@"REMReminder") != nil
                 && [NSClassFromString(@"REMReminderChangeItem") instancesRespondToSelector:@selector(urgentAlarmContext)];
    });
    return available;
}

+ (BOOL)setUrgent:(BOOL)urgent
    forReminderIdentifier:(NSString *)identifier
       externalIdentifier:(NSString *)externalIdentifier
                    error:(NSError **)error {
    if (!self.isAvailable) {
        if (error) *error = NTError(1, @"ReminderKit's Urgent API isn't available on this macOS.");
        return NO;
    }

    id<NTRemStore> store = [[NSClassFromString(@"REMStore") alloc] init];
    id reminder = nil;

    // 1. By object ID — EventKit's calendarItemIdentifier is normally the ReminderKit UUID.
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:identifier];
    id<NTRemReminderClass> reminderClass = (id<NTRemReminderClass>)NSClassFromString(@"REMReminder");
    if (uuid && [reminderClass respondsToSelector:@selector(objectIDWithUUID:)]
             && [store respondsToSelector:@selector(fetchReminderWithObjectID:error:)]) {
        id objectID = [reminderClass objectIDWithUUID:uuid];
        if (objectID) reminder = [store fetchReminderWithObjectID:objectID error:NULL];
    }
    // 2. By external identifier (the iCloud/CalDAV UID).
    if (!reminder && externalIdentifier.length
        && [store respondsToSelector:@selector(fetchAllRemindersWithExternalIdentifier:error:)]) {
        reminder = [[store fetchAllRemindersWithExternalIdentifier:externalIdentifier error:NULL] firstObject];
    }
    if (!reminder) {
        if (error) *error = NTError(2, [NSString stringWithFormat:@"Reminder %@ not found in ReminderKit.", identifier]);
        return NO;
    }

    // Already in the requested state? Nothing to save.
    if ([reminder respondsToSelector:@selector(urgentAlarmContext)]) {
        id<NTRemUrgentContext> current = [(id<NTRemReminder>)reminder urgentAlarmContext];
        if ([current respondsToSelector:@selector(isUrgentStateEnabledForCurrentUser)]
            && current.isUrgentStateEnabledForCurrentUser == urgent) {
            return YES;
        }
    }

    id<NTRemSaveRequest> request = [[NSClassFromString(@"REMSaveRequest") alloc] initWithStore:store];
    id<NTRemReminder> changeItem = [request updateReminder:reminder];
    id<NTRemUrgentContext> context = [changeItem respondsToSelector:@selector(urgentAlarmContext)] ? [changeItem urgentAlarmContext] : nil;
    if (![context respondsToSelector:@selector(setIsUrgentStateEnabledForCurrentUser:)]) {
        if (error) *error = NTError(3, @"ReminderKit change item has no Urgent context.");
        return NO;
    }
    [context setIsUrgentStateEnabledForCurrentUser:urgent];
    return [request saveSynchronouslyWithError:error];
}

@end
