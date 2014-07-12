#import "PreferencesUtil.h"
#import "CryptoTools.h"
#import "Constraints.h"
#import "PhoneNumber.h"
#import "Util.h"

#import "NotificationManifest.h"

#define CALL_STREAM_DES_BUFFER_LEVEL_KEY @"CallStreamDesiredBufferLevel"

#define PHONE_DIRECTORY_BLOOM_FILTER_HASH_COUNT_KEY @"Directory Bloom Hash Count"
#define PHONE_DIRECTORY_BLOOM_FILTER_DATA_KEY @"Directory Bloom Data"
#define PHONE_DIRECTORY_EXPIRATION @"Directory Expiration"

#define DEFAULT_CALL_STREAM_DES_BUFFER_LEVEL 0.5

#define SETTINGS_EXPANDED_ROW_PREF_DICT_KEY @"Settings Expanded Row Pref Dict Key"

#define FRESH_INSTALL_TUTORIALS_ENABLED_KEY @"Fresh Install Tutorials Enabled Key"
#define CONTACT_IMAGES_ENABLED_KEY @"Contact Images Enabled Key"
#define AUTOCORRECT_ENABLED_KEY @"Autocorrect Enabled Key"
#define HISTORY_LOG_ENABLED_KEY @"History Log Enabled Key"
#define ANONYMOUS_FEEDBACK_ENABLED_KEY @"Anonymous Feedback Enabled Key"

#define DATE_FORMAT_KEY @"Date Format Key"
#define DATE_FORMAT_1 @"dd-MM-yyyy"
#define DATE_FORMAT_2 @"yyyy-MM-dd"
#define DATE_FORMAT_3 @"MM-dd-yyyy"
#define DATE_FORMAT_4 @"dd/MM/yyyy"
#define DATE_FORMAT_5 @"yyyy/MM/dd"
#define DATE_FORMAT_6 @"MM/dd/yyyy"

@implementation PropertyListPreferences (PropertyUtil)

-(PhoneNumberDirectoryFilter*) tryGetSavedPhoneNumberDirectory {
    NSUInteger hashCount = [[self tryGetValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_HASH_COUNT_KEY] unsignedIntegerValue];
    NSData* data = [self tryGetValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_DATA_KEY];
    NSDate* expiration = [self tryGetValueForKey:PHONE_DIRECTORY_EXPIRATION];
    if (hashCount == 0 || [data length] == 0 || expiration == nil) return nil;
    BloomFilter* bloomFilter = [BloomFilter bloomFilterWithHashCount:hashCount andData:data];
    return [PhoneNumberDirectoryFilter phoneNumberDirectoryFilterWithBloomFilter:bloomFilter
                                                               andExpirationDate:expiration];
}
-(void) setSavedPhoneNumberDirectory:(PhoneNumberDirectoryFilter*)phoneNumberDirectoryFilter {
    // note: clearing before setting so that torn reads can be detected
    [self setValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_DATA_KEY toValue:nil];
    [self setValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_HASH_COUNT_KEY toValue:nil];
    [self setValueForKey:PHONE_DIRECTORY_EXPIRATION toValue:nil];
    if (phoneNumberDirectoryFilter == nil) return;
    
    NSData* data = [[phoneNumberDirectoryFilter bloomFilter] data];
    NSNumber* hashCount = [NSNumber numberWithUnsignedInteger:[[phoneNumberDirectoryFilter bloomFilter] hashCount]];
    NSDate* expiry = [phoneNumberDirectoryFilter getExpirationDate];
    [self setValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_DATA_KEY toValue:data];
    [self setValueForKey:PHONE_DIRECTORY_BLOOM_FILTER_HASH_COUNT_KEY toValue:hashCount];
    [self setValueForKey:PHONE_DIRECTORY_EXPIRATION toValue:expiry];
    [self sendDirectoryUpdateNotification];
}

-(void) sendDirectoryUpdateNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DIRECTORY_UPDATE object:nil];
}

-(NSTimeInterval) getCachedOrDefaultDesiredBufferDepth {
    id v = [self tryGetValueForKey:CALL_STREAM_DES_BUFFER_LEVEL_KEY];
    if (v == nil) return DEFAULT_CALL_STREAM_DES_BUFFER_LEVEL;
    return [v doubleValue];
}
-(void) setCachedDesiredBufferDepth:(double)value {
    require(value >= 0);
    [self setValueForKey:CALL_STREAM_DES_BUFFER_LEVEL_KEY toValue:[NSNumber numberWithDouble:value]];
}

-(void) setSettingsRowExpandedPrefs:(NSArray *)prefs {
	[self setValueForKey:SETTINGS_EXPANDED_ROW_PREF_DICT_KEY toValue:prefs];
}

-(NSArray *) getOrGenerateSettingsRowExpandedPrefs {
    NSArray *prefs = [self tryGetValueForKey:SETTINGS_EXPANDED_ROW_PREF_DICT_KEY];
    if (!prefs) {
        prefs = @[[NSNumber numberWithBool:true], [NSNumber numberWithBool:true], [NSNumber numberWithBool:true], [NSNumber numberWithBool:true]];
    }
    return prefs;
}

-(NSArray *) getAvailableDateFormats {
    return @[DATE_FORMAT_1, DATE_FORMAT_2, DATE_FORMAT_3, DATE_FORMAT_4, DATE_FORMAT_5, DATE_FORMAT_6];
}

- (NSString *)getDateFormat {
    NSString *format = [self tryGetValueForKey:DATE_FORMAT_KEY];
    if (format) {
        return format;
    } else {
        return DATE_FORMAT_1;
    }
}

- (NSString *)getDateFormatKey {
    return DATE_FORMAT_KEY;
}
-(BOOL) getFreshInstallTutorialsEnabled {
    NSNumber *preference = [self tryGetValueForKey:FRESH_INSTALL_TUTORIALS_ENABLED_KEY];
    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}
-(BOOL) getContactImagesEnabled {
    NSNumber *preference = [self tryGetValueForKey:CONTACT_IMAGES_ENABLED_KEY];
    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}
-(BOOL) getAutocorrectEnabled {
    NSNumber *preference = [self tryGetValueForKey:AUTOCORRECT_ENABLED_KEY];
    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}
-(BOOL) getHistoryLogEnabled {
    NSNumber *preference = [self tryGetValueForKey:HISTORY_LOG_ENABLED_KEY];
    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}
-(BOOL) getAnonymousFeedbackEnabled {
    NSNumber *preference = [self tryGetValueForKey:ANONYMOUS_FEEDBACK_ENABLED_KEY];
    if (preference) {
        return [preference boolValue];
    } else {
        return NO;
    }
}

-(void) setDateFormat:(NSString *)format {
    [self setValueForKey:DATE_FORMAT_KEY toValue:format];
}

-(void) setFreshInstallTutorialsEnabled:(BOOL)enabled {
    [self setValueForKey:FRESH_INSTALL_TUTORIALS_ENABLED_KEY toValue:[NSNumber numberWithBool:enabled]];
}
-(void) setContactImagesEnabled:(BOOL)enabled {
    [self setValueForKey:CONTACT_IMAGES_ENABLED_KEY toValue:[NSNumber numberWithBool:enabled]];
}
-(void) setAutocorrectEnabled:(BOOL)enabled {
    [self setValueForKey:AUTOCORRECT_ENABLED_KEY toValue:[NSNumber numberWithBool:enabled]];
}
-(void) setHistoryLogEnabled:(BOOL)enabled {
    [self setValueForKey:HISTORY_LOG_ENABLED_KEY toValue:[NSNumber numberWithBool:enabled]];
}
-(void) setAnonymousFeedbackEnabled:(BOOL)enabled {
    [self setValueForKey:ANONYMOUS_FEEDBACK_ENABLED_KEY toValue:[NSNumber numberWithBool:enabled]];
}
@end
