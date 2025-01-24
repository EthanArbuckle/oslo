//
//  config.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OSLogLevel) {
    OSLogLevelDebug,
    OSLogLevelInfo,
    OSLogLevelWarning,
    OSLogLevelError
};

@interface OSLogFilter : NSObject
@property (nonatomic, copy) NSString *processPattern;
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, assign) OSLogLevel level;
@property (nonatomic, strong) NSDate *after;
@property (nonatomic, strong) NSDate *before;
@property (nonatomic, copy) NSString *contains;
@property (nonatomic, copy) NSString *exclude;
@end

@interface OSLogOptions : NSObject
@property (nonatomic, assign) BOOL live;
@property (nonatomic, assign) BOOL group;
@property (nonatomic, assign) BOOL json;
@property (nonatomic, assign) BOOL dropRepeatedMessages;
@property (nonatomic, copy) NSString *outputFile;
@end

@interface OSLogConfig : NSObject
@property (nonatomic, strong) OSLogFilter *filter;
@property (nonatomic, strong) OSLogOptions *options;

+ (instancetype)parseWithArgc:(int)argc argv:(char **)argv;
- (NSPredicate *)buildPredicate;

@end
