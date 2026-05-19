#import "LCPresentation.h"
#import "LCString.h"

NSString *
LCPresentationStringForValue(id value, NSString *key, BOOL detail)
{
    NSString *stringValue;

    if (value == nil) {
        return detail ? LCString(@"State.Confidence.NotAvailable") : @"";
    }

    if ([key isEqualToString:@"pid"] && [value intValue] < 0) {
        return detail ? LCString(@"State.Confidence.NotAvailable") : @"";
    }

    stringValue = [value description];

    if ([stringValue isEqualToString:@"-"]) {
        return detail ? LCString(@"State.Confidence.NotAvailable") : @"";
    }

    if ([key isEqualToString:@"kind"]) {
        if ([stringValue isEqualToString:@"Apple system component"]) {
            return LCString(@"Classification.AppleSystemComponent");
        }

        if ([stringValue isEqualToString:@"Apple application"]) {
            return LCString(@"Classification.AppleApplication");
        }

        if ([stringValue isEqualToString:@"command-line tool"]) {
            return LCString(@"Classification.CommandLineTool");
        }

        if ([stringValue isEqualToString:@"user application"]) {
            return LCString(@"Classification.UserApplication");
        }

        if ([stringValue isEqualToString:@"developer tool"]) {
            return LCString(@"Classification.DeveloperTool");
        }

        if ([stringValue isEqualToString:@"MacPorts tool"]) {
            return LCString(@"Classification.MacPortsTool");
        }

        if ([stringValue isEqualToString:@"unknown"]) {
            return LCString(@"Classification.ObservedOnly");
        }
    }

    if ([key isEqualToString:@"confidence"] && [stringValue isEqualToString:@"unknown"]) {
        return detail ? LCString(@"State.Confidence.NotAvailable") : @"";
    }

    if ([key isEqualToString:@"executable"]) {
        if ([stringValue isEqualToString:@"unknown"]) {
            return detail ? LCString(@"State.Executable.NotReported.Detail") : LCString(@"State.Executable.NotReported");
        }

        if ([stringValue isEqualToString:@"present"]) {
            return LCString(@"State.Executable.Present");
        }

        if ([stringValue isEqualToString:@"missing"]) {
            return LCString(@"State.Executable.NotPresent");
        }

        if ([stringValue isEqualToString:@"directory"]) {
            return LCString(@"State.Executable.Directory");
        }
    }

    if ([key isEqualToString:@"evidenceType"]) {
        NSString *localizedKey;

        localizedKey = [NSString stringWithFormat:@"EvidenceType.%@", stringValue];

        return LCString(localizedKey);
    }

    if ([key isEqualToString:@"resolutionState"]) {
        NSString *localizedKey;

        localizedKey = [NSString stringWithFormat:@"ResolutionState.%@", stringValue];

        return LCString(localizedKey);
    }

    return stringValue;
}
