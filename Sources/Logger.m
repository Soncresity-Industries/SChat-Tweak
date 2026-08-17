#import "Logger.h"
#import <stdarg.h>

void SChatLogImpl(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);

    NSLog(@"[SChat] %@", message);
}
