#import <Foundation/Foundation.h>

FOUNDATION_EXPORT void SChatLogImpl(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

#define SChatLog(fmt, ...) SChatLogImpl((fmt), ##__VA_ARGS__)
