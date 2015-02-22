//
//  ZSWStringParserTag.m
//  Pods
//
//  Created by Zachary West on 2015-02-21.
//
//

#import "ZSWStringParserTag.h"

@interface ZSWStringParserTag()
@property (nonatomic, readwrite) NSString *tagName;
@property (nonatomic, readwrite) NSInteger location;
@property (nonatomic) NSInteger endLocation;

@property (nonatomic) NSDictionary *tagAttributes;
@end

@implementation ZSWStringParserTag

- (instancetype)initWithTagName:(NSString *)tagName
                  startLocation:(NSInteger)location {
    self = [super init];
    if (self) {
        self.tagName = tagName;
        self.location = location;
    }
    return self;
}

- (BOOL)isEndingTag {
    return [self.tagName hasPrefix:@"/"];
}

- (BOOL)isEndedByTag:(ZSWStringParserTag *)tag {
    if (!tag.isEndingTag) {
        return NO;
    }
    
    if (![[tag.tagName substringFromIndex:1] isEqualToString:self.tagName]) {
        return NO;
    }
    
    return YES;
}

- (void)updateWithTag:(ZSWStringParserTag *)tag {
    NSAssert([self isEndedByTag:tag], @"Didn't check before updating tag");
    self.endLocation = tag.location;
}

- (NSRange)tagRange {
    if (self.endLocation < self.location) {
        return NSMakeRange(self.location, 0);
    } else {
        return NSMakeRange(self.location, self.endLocation - self.location);
    }
}

- (void)addRawTagAttributes:(NSString *)rawTagAttributes {
    NSScanner *scanner = [NSScanner scannerWithString:rawTagAttributes];
    scanner.charactersToBeSkipped = nil;
    
    NSMutableDictionary *tagAttributes = [NSMutableDictionary dictionary];
    
    NSCharacterSet *nameBreakSet = [NSCharacterSet characterSetWithCharactersInString:@" ="];
    NSCharacterSet *quoteCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"" @"'"];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    
    while (!scanner.isAtEnd) {
        // eat any whitespace at the start
        [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
        
        // Scan up to '=' or ' '
        NSString *attributeName;
        [scanner scanUpToCharactersFromSet:nameBreakSet intoString:&attributeName];
        
        NSString *breakString;
        [scanner scanCharactersFromSet:nameBreakSet intoString:&breakString];
        
        if (scanner.isAtEnd || [breakString rangeOfString:@"="].location == NSNotFound) {
            // No equal was found, so give some generic value.
            tagAttributes[attributeName] = [NSNull null];
        } else {
            // We had an equal! Yay! We can use the value.
            NSString *quote;
            BOOL ateQuote = [scanner scanCharactersFromSet:quoteCharacterSet intoString:&quote];
            
            NSString *attributeValue;
            if (ateQuote) {
                // For empty values (e.g. ''), we need to see if we scanned more than one quote.
                NSInteger count = 0;
                for (NSInteger idx = 0; idx < quote.length; idx++) {
                    count += [quoteCharacterSet characterIsMember:[quote characterAtIndex:idx]];
                }
                
                if (count > 1) {
                    attributeValue = @"";
                } else {
                    [scanner scanUpToCharactersFromSet:quoteCharacterSet intoString:&attributeValue];
                    [scanner scanCharactersFromSet:quoteCharacterSet intoString:NULL];
                }
            } else {
                [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&attributeValue];
                [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
            }
            
            tagAttributes[attributeName] = attributeValue ?: [NSNull null];
        }
    }
    
    NSMutableDictionary *updatedAttributes = [NSMutableDictionary dictionaryWithDictionary:self.tagAttributes];
    [updatedAttributes addEntriesFromDictionary:tagAttributes];
    self.tagAttributes = [updatedAttributes copy];
}

@end
