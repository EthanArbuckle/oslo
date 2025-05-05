//
//  config.m
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import <getopt.h>
#import "config.h"

@implementation OSloLogFilter
@end

@implementation OSloLogOptions
- (id)init {
    if ((self = [super init])) {
        _live = YES;
    }
    return self;
}
@end

@implementation OSLogConfig

+ (NSDate *)parseTimeOffset:(NSString *)offset {
    // Negative time offset: -1h, -30m, -1d, -1w
    if ([offset hasPrefix:@"-"]) {
        NSString *unit = [offset substringFromIndex:offset.length - 1];
        NSTimeInterval interval = [[offset substringToIndex:offset.length - 1] doubleValue];
        if ([unit isEqualToString:@"h"]) {
            return [NSDate dateWithTimeIntervalSinceNow:interval * 60 * 60];
        } else if ([unit isEqualToString:@"m"]) {
            return [NSDate dateWithTimeIntervalSinceNow:interval * 60];
        } else if ([unit isEqualToString:@"d"]) {
            return [NSDate dateWithTimeIntervalSinceNow:interval * 60 * 60 * 24];
        } else if ([unit isEqualToString:@"w"]) {
            return [NSDate dateWithTimeIntervalSinceNow:interval * 60 * 60 * 24 * 7];
        }
    }
    // Date and time: 2025-01-23 12:34:56
    else if ([offset containsString:@" "] && [offset componentsSeparatedByString:@"-"].count == 3) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter dateFromString:offset];
    }
    // Date only: 2025-01-23
    else if ([offset componentsSeparatedByString:@"-"].count == 3) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        return [formatter dateFromString:offset];
    }
    // Time only: 12:34:56
    else if ([offset componentsSeparatedByString:@":"].count == 2) {
        // Assume they're going for HH:mm:00
        offset = [offset stringByAppendingString:@":00"];
    }
    
    if ([offset componentsSeparatedByString:@":"].count == 3) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        return [formatter dateFromString:offset];
    }
    
    return nil;
}

+ (instancetype)parseWithArgc:(int)argc argv:(char **)argv {
    OSLogConfig *config = [[OSLogConfig alloc] init];
    config.filter = [[OSloLogFilter alloc] init];
    config.options = [[OSloLogOptions alloc] init];
    config.filter.level = OSLogLevelNotice;
    config.options.noColor = NO;

    config.filter.containsPatterns = [[NSMutableArray alloc] init];
    config.filter.excludePatterns = [[NSMutableArray alloc] init];
    
    static struct option long_options[] = {
        {"level", required_argument, 0, 'L'},
        {"after", required_argument, 0, 'a'},
        {"before", required_argument, 0, 'b'},
        {"contains", required_argument, 0, 'c'},
        {"exclude", required_argument, 0, 'e'},
        {"image", required_argument, 0, 'i'},
        {"library", required_argument, 0, 'l'},
        {"stored", no_argument, 0, 's'},
        {"group", no_argument, 0, 'g'},
        {"json", no_argument, 0, 'j'},
        {"file", required_argument, 0, 'f'},
        {"repeats", no_argument, 0, 'r'},
        {"no-color", no_argument, 0, 'N'},
        {"strip", no_argument, 0, 'S'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };
    
    int opt;
    int option_index = 0;
    
    while ((opt = getopt_long(argc, argv, "L:a:b:c:e:l:sgjrNSf:i:h", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'L': {
                NSString *level = [NSString stringWithUTF8String:optarg];
                if ([level caseInsensitiveCompare:@"notice"] == NSOrderedSame) {
                    config.filter.level = OSLogLevelNotice;
                }
                else if ([level caseInsensitiveCompare:@"debug"] == NSOrderedSame) {
                    config.filter.level = OSLogLevelDebug;
                }
                else if ([level caseInsensitiveCompare:@"info"] == NSOrderedSame) {
                    config.filter.level = OSLogLevelInfo;
                }
                else if ([level caseInsensitiveCompare:@"error"] == NSOrderedSame) {
                    config.filter.level = OSLogLevelError;
                }
                else if ([level caseInsensitiveCompare:@"fault"] == NSOrderedSame) {
                    config.filter.level = OSLogLevelFault;
                }
                else {
                    printf("Invalid log level: %s\nValid levels: notice, info, debug, error, fault\n", level.UTF8String);
                    exit(1);
                }
                break;
            }
            case 'a': {
                NSString *after = [NSString stringWithUTF8String:optarg];
                NSDate *date = [self parseTimeOffset:after];
                if (!date) {
                    printf("Invalid time offset: %s\n", after.UTF8String);
                    exit(1);
                }
                config.options.live = NO;
                config.filter.after = date;
                break;
            }
            case 'b': {
                NSString *before = [NSString stringWithUTF8String:optarg];
                NSDate *date = [self parseTimeOffset:before];
                if (!date) {
                    printf("Invalid time offset: %s\n", before.UTF8String);
                    exit(1);
                }
                config.options.live = NO;
                config.filter.before = date;
                break;
            }
            case 'c':
                [(NSMutableArray *)config.filter.containsPatterns addObject:[NSString stringWithUTF8String:optarg]];
                break;
            case 'e':
                [(NSMutableArray *)config.filter.excludePatterns addObject:[NSString stringWithUTF8String:optarg]];
                break;
            case 'l':
            case 'i':
                config.filter.imagePath = [NSString stringWithUTF8String:optarg];
                break;
            case 's':
                config.options.live = NO;
                break;
            case 'g':
                config.options.group = YES;
                break;
            case 'j':
                config.options.json = YES;
                break;
            case 'r':
                config.options.dropRepeatedMessages = YES;
                break;
            case 'N':
                config.options.noColor = YES;
                break;
            case 'f':
                config.options.outputFile = [NSString stringWithUTF8String:optarg];
                break;
            case 'S':
                config.options.stripNewlines = YES;
                break;
            case 'h':
                [self printUsage];
                exit(0);
            default:
                [self printUsage];
                exit(1);
        }
    }
    
    if ((config.filter.after && config.filter.before) && ([config.filter.after compare:config.filter.before] == NSOrderedDescending)) {
        printf("Error: --after time is later than --before time\n");
        exit(1);
    }
    
    if ((config.filter.after || config.filter.before) && config.options.live) {
        printf("Applying time filters to live logs. If you want to search older logs, use -s / --stored\n");
    }
    
    if (optind < argc) {
        NSString *processArg = [NSString stringWithUTF8String:argv[optind]];
        NSScanner *scanner = [NSScanner scannerWithString:processArg];
        int pid = 0;
        if ([scanner scanInt:&pid] && scanner.isAtEnd) {
            config.filter.pid = pid;
        }
        else {
            config.filter.processPattern = processArg;
        }
    }
    
    if (config.options.group && config.options.live) {
        printf("Error: Grouping only works with stored logs\n");
        exit(1);
    }
    
    return config;
}

+ (void)printUsage {
    printf("Usage: oslo [process] [filters] [options]\n\n");
    printf("Process:\n");
    printf("  <name>         Process name (case insensitive substring match)\n");
    printf("  <pid>          Process ID\n");
    printf("                 (shows all processes if omitted)\n\n");
    printf("Filters:\n");
    printf("  -L, --level    Log level (notice, debug, info, error, fault)\n");
    printf("  -a, --after    Time format options:\n");
    printf("                   Offset: -1h, -30m, -1d, -1w\n");
    printf("                   Date: 2025-01-23\n");
    printf("                   Time: 12:34:56\n");
    printf("                   Both: 2025-01-23 12:34:56\n");
    printf("  -b, --before   Same time formats as --after\n");
    printf("  -c, --contains Include messages containing text (case insensitive)\n");
    printf("  -x or -e, --exclude  Exclude messages containing text (case insensitive)\n");
    printf("  -l or -i, --library    Filter by library path\n\n");
    printf("Options:\n");
    printf("  -g, --group    Group by process _(only for past logs)_\n");
    printf("  -j, --json     Output in JSON format _(only for past logs)\n");
    printf("  -f, --file     Write output to a file\n");
    printf("  -r, --repeats  Collapse repeated identical messages (default: disabled)\n");
    printf("  -N, --no-color Disable color output\n");
    printf("  -S, --strip    Strip newlines from output\n");
    printf("  -h, --help     Show this help message\n");
}

- (NSPredicate *)buildPredicate {
    NSMutableArray *subpredicates = [NSMutableArray array];
    
    NSString *(^wrapInputForFuzzyMatch)(NSString *) = ^NSString *(NSString *input) {
        NSString *wrapped = [input stringByReplacingOccurrencesOfString:@"*" withString:@"[^/]*"];
        if (![wrapped hasPrefix:@".*"]) {
            if ([wrapped hasPrefix:@"*"]) {
                wrapped = [@"." stringByAppendingString:wrapped];
            }
            else {
                wrapped = [@".*" stringByAppendingString:wrapped];
            }
        }
        if (![wrapped hasSuffix:@".*"]) {
            if ([wrapped hasSuffix:@"*"]) {
                wrapped = [wrapped substringToIndex:wrapped.length - 1];
                wrapped = [wrapped stringByAppendingString:@".*"];
            }
            else {
                wrapped = [wrapped stringByAppendingString:@".*"];
            }
        }
        return wrapped;
    };
    
    if (self.filter.processPattern) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"processImagePath MATCHES[c] %@", wrapInputForFuzzyMatch(self.filter.processPattern)]];
    }
    
    if (self.filter.pid) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"processIdentifier == %d", self.filter.pid]];
    }

    for (NSString *pattern in self.filter.containsPatterns) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"composedMessage MATCHES[c] %@", wrapInputForFuzzyMatch(pattern)]];
    }
    
    for (NSString *pattern in self.filter.excludePatterns) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"NOT (composedMessage MATCHES[c] %@ OR senderImagePath MATCHES[c] %@)",
            wrapInputForFuzzyMatch(pattern), wrapInputForFuzzyMatch(pattern)]];
    }

    if (self.filter.imagePath) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"senderImagePath MATCHES[c] %@", wrapInputForFuzzyMatch(self.filter.imagePath)]];
    }

    if (self.filter.after) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"date >= %@", self.filter.after]];
    }
    
    if (self.filter.before) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"date <= %@", self.filter.before]];
    }
    
    if (self.filter.level) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"logType == %d", self.filter.level]];
    }
    
    if (subpredicates.count == 0) {
        return [NSPredicate predicateWithValue:YES];
    } else if (subpredicates.count == 1) {
        return subpredicates.firstObject;
    } else {
        return [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    }
}

@end
