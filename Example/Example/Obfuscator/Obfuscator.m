//
//  Obfuscator.m
//
//  Created by PJ on 15/06/2015.
//  Copyright (c) 2015 PJ Engineering and Business Solutions Pty Ltd. All rights reserved.
//

#import "Obfuscator.h"

@interface Obfuscator ()
    @property (strong) NSString *salt;

    - (NSString *)printHex:(NSString *)string;
    - (NSString *)CStringToNSString:(const unsigned char *)cstring;
    - (unsigned char *)convertNSStringtoCString:(NSString *)string;
@end

@implementation Obfuscator


+ (instancetype)newWithSalt:(Class)class, ...
{
    NSMutableString *classes;
    
    id eachClass;
    va_list argumentList;
    if (class) // The first argument isn't part of the varargs list,
    {
        classes = [[NSMutableString alloc] initWithString:NSStringFromClass(class)];
        va_start(argumentList, class); // Start scanning for arguments after class.
        while ((eachClass = va_arg(argumentList, id))) // As many times as we can get an argument of type "id"
            [classes appendString:NSStringFromClass(eachClass)];
        va_end(argumentList);
    }
    
    return [self newWithSaltUnsafe:[classes copy]];
}

+ (instancetype)newWithSaltUnsafe:(NSString *)string
{
    Obfuscator *o = [[Obfuscator alloc] init];
    
    NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // Get the SHA1 of a class name, to form the obfuscator.
    unsigned char obfuscator[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(d.bytes, (CC_LONG)d.length, obfuscator);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", obfuscator[i]];
    }
    o.salt = [output copy];
    
    return o;
}

- (NSString *)hexByObfuscatingString:(NSString *)string
{
    NSString *hexCode = @"";

#ifdef DEBUG

    //Convert string to C-String
    unsigned char * c_string = [self convertNSStringtoCString:string];
    
    hexCode = [self printHex:[self reveal:c_string]];
    
    free(c_string);
    
    NSLog(@"Objective-C Code:\nextern const unsigned char key[];\n//Original: %@\n%@\n*********REMOVE THIS BEFORE DEPLOYMENT*********\n", string,hexCode);

#endif
        
    return hexCode;
}

- (NSString *)reveal:(const unsigned char *)string
{
    // Create data object from the C-String
    NSData *data = [[self CStringToNSString:string] dataUsingEncoding:NSUTF8StringEncoding];
    
    // Get pointer to data to obfuscate
    char *dataPtr = (char *) [data bytes];
    
    // Get pointer to key data
    char *keyData = (char *) [[self.salt dataUsingEncoding:NSUTF8StringEncoding] bytes];
    
    // Points to each char in sequence in the key
    char *keyPtr = keyData;
    int keyIndex = 0;
    
    // For each character in data, xor with current value in key
    for (int x = 0; x < [data length]; x++)
    {
        // Replace current character in data with
        // current character xor'd with current key value.
        // Bump each pointer to the next character
        *dataPtr = *dataPtr ^ *keyPtr;
        dataPtr++;
        keyPtr++;
        
        // If at end of key data, reset count and
        // set key pointer back to start of key value
        if (++keyIndex == [self.salt length])
            keyIndex = 0, keyPtr = keyData;
    }
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


#pragma mark - Helper Functions

/*!
 * @brief Converts C-String to NSString.
 * @discussion For use with reveal:
 * @param cstring Hard-Coded C-String
 * @return NSString version of cstring
 */
- (NSString *)CStringToNSString:(const unsigned char *)cstring
{
    return [[NSString alloc] initWithFormat:@"%s", cstring];
}

/*!
 * @brief Converts a NSString to a C-String.
 * @discussion Used by hexByObfuscatingString: method.
 * Uses malloc function which returns a pointer. See warning.
 * @param string A NSString to be converted to a C-String
 * @warning Make sure you free the generated pointer to avoid a memory leak.
 * @return A pointer to the initial char of the C-String.
 */
- (unsigned char *)convertNSStringtoCString:(NSString *)string
{
    unsigned long length = [string length];
    
    unsigned char *temp;
    temp = (unsigned char *)malloc((length+1) * sizeof (unsigned char)); //Holds C String
    for (int i=0; i<length; i++) {
        temp[i] = (unsigned char)[string characterAtIndex:i];
    }
    temp[length] = 0;
    
    return temp;
}

/*!
 * @brief Generates the Objective-C Code to define and initialize a global C-String (initialized in hexadecimal).
 * @discussion Hard-coded NSString objects are easily discoverable when using a jail-broken iPhone.
 * It is better to obfuscate the desired strings as C-Strings initialized in hexadecimal notation.
 * @param string A string that you wish to hardcode in your app as a C-String.
 * @return Objective-C code to embed in your app to define and initialize a global C-String.
 */
- (NSString *)printHex:(NSString *)string
{
    NSMutableString *temp = [[NSMutableString alloc] initWithString:@""];
    
    [temp appendString:@"const unsigned char key[] = { "];
    
    for (int i = 0; i < [string length]; i++)
    {
        if (i != 0)
            [temp appendString:@", "];
        
        int ascii = [string characterAtIndex:i];
        NSString *t = [[[NSString alloc] initWithFormat:@"%x",ascii] uppercaseString];
        [temp appendFormat:@"0x%@", t];
    }
    
    [temp appendString:@", 0x00 };"];
    return [temp copy];
}

@end
