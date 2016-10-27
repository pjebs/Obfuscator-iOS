//
//  Obfuscator.m
//
//  Created by PJ on 11/07/2015.
//  Copyright (c) 2015 PJ Engineering and Business Solutions Pty Ltd. All rights reserved.
//

#import "Obfuscator.h"

#include <CommonCrypto/CommonCrypto.h>

@interface Obfuscator ()
    @property (strong) NSString *salt;

    + (NSString *)hashSaltUsingSHA1:(NSString *)salt;
    + (NSString *)printHex:(NSString *)string;
    + (NSString *)printHex:(NSString *)string WithKey:(NSString *)key;
    - (NSString *)CStringToNSString:(const unsigned char *)cstring;
    - (unsigned char *)convertNSStringtoCString:(NSString *)string;
    - (NSString *)hexByObfuscatingString:(NSString *)string silence:(BOOL)silence;
    + (BOOL)generateCodeWithSaltUnsafe:(NSString *)salt WithStrings:(NSArray *)strings silence:(BOOL)silence successfulP:(NSMutableArray **)successfulP unsuccessfulP:(NSMutableArray **)unsuccessfulP;
    + (NSArray *) allPermutationsOfArray:(NSArray*)array;
    + (NSString *) stringFromClasses:(NSArray *)classes;
    + (void) logCodeWithSuccessful:(NSArray *)successful unsuccessful:(NSArray *)unsuccessful;
@end

@implementation Obfuscator

// Keeps a database of salts in unhashed format.
// Essential when bridging Obfuscator to Swift since
// + (instancetype)newWithSalt:(Class)class, ...
// does not bridge over.
static NSMutableDictionary *saltDatabase;


+ (void)storeKey:(NSString *)key forSalt:(Class)class, ...
{
    if (saltDatabase == nil)
        saltDatabase = [[NSMutableDictionary alloc] init];
    
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
    
    [saltDatabase setValue:[classes copy] forKey:key];
}

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

+ (instancetype)newUsingStoredSalt:(NSString *)key
{
    NSString *storedSalt = [saltDatabase valueForKey:key];
    if (storedSalt == nil)
        return nil;
    
    Obfuscator *o = [Obfuscator newWithSaltUnsafe:storedSalt];
    
    return o;
}

+ (instancetype)newWithSaltUnsafe:(NSString *)string
{
    Obfuscator *o = [[Obfuscator alloc] init];
    
    o.salt = [self hashSaltUsingSHA1:string];
    
    return o;
}

- (NSString *)hexByObfuscatingString:(NSString *)string
{
    return [self hexByObfuscatingString:string silence:NO];
}

- (NSString *)hexByObfuscatingString:(NSString *)string silence:(BOOL)silence
{
    
#ifdef DEBUG
    
    //Convert string to C-String
    unsigned char * c_string = [self convertNSStringtoCString:string];
    NSString *obfuscatedString = [self reveal:c_string];
    
    //Test if Obfuscator worked
    unsigned char * c_string_obfuscated = [self convertNSStringtoCString:obfuscatedString];
    NSString *backToOriginal = [self reveal:c_string_obfuscated];
    free(c_string_obfuscated);
    
    free(c_string);
    
    if ([string isEqualToString:backToOriginal])
    {
        NSString *hexCode = [Obfuscator printHex:obfuscatedString];
        if (silence == NO)
            NSLog(@"Objective-C Code:\nextern const unsigned char *key;\n//Original: \"%@\"\n%@\nconst unsigned char *key = &_key[0];\n*********REMOVE THIS BEFORE DEPLOYMENT*********\n", string, hexCode);
        return obfuscatedString;
    }
    else
    {
        if (silence == NO)
            NSLog(@"Could not obfuscate: %@ - Use different salt", string);
        return nil;
    }
    
#endif
    
    return nil;
}

+ (NSString *)reveal:(const unsigned char *)string UsingStoredSalt:(NSString *)key
{
    NSString *storedSalt = [saltDatabase valueForKey:key];
    if (storedSalt == nil)
        return nil;
    
    Obfuscator *o = [Obfuscator newWithSaltUnsafe:storedSalt];
    return [o reveal:string];
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

#pragma mark - Generating Valid Objective-C Code

+ (BOOL)generateCodeWithSaltUnsafe:(NSString *)salt WithStrings:(NSArray *)strings
{
#ifdef DEBUG
    return [self generateCodeWithSaltUnsafe:salt WithStrings:strings silence:NO successfulP:nil unsuccessfulP:nil];
#endif
    
    return YES;
}

+ (BOOL)generateCodeWithSalt:(NSArray *)classes WithStrings:(NSArray *)strings
{
#ifdef DEBUG
    NSArray *successful;
    NSArray *unsuccessful;
    NSArray *selectedClasses;
    
    //Get permutations of salt
    NSArray *permutations = [self allPermutationsOfArray:classes];
    
    //Loop through all permutations
    for (NSArray *permutation in permutations) {
        NSString *salt = [self stringFromClasses:permutation];
//        NSLog(@"*+*+*+*+*+**+*+*+*+*+*+*+*+*+*+*+*");
        
        //Create MutableArrays to temporarily store successful and unsuccessful obfuscated strings
        NSMutableArray *s = [[NSMutableArray alloc] init];
        NSMutableArray *u = [[NSMutableArray alloc] init]; //Stores any unsuccessful strings
        
        [self generateCodeWithSaltUnsafe:salt WithStrings:strings silence:YES successfulP:&s unsuccessfulP:&u];
        
        if (successful == nil)
        {
            successful = [s copy];
            unsuccessful = [u copy];
            selectedClasses = permutation;
        }
        else
        {
            if ([successful count] < [s count])
            {
                //This combination is better
                successful = [s copy];
                unsuccessful = [u copy];
                selectedClasses = permutation;
            }
            
            if ([u count] == 0) //Perfect combination. All strings were obfuscated.
            {
                break;
            }
        }
        
//        NSLog(@"*+*+*+*+*+**+*+*+*+*+*+*+*+*+*+*+*");
    }

    //Print out best salt.
    NSMutableString *salt = [[NSMutableString alloc] init];
    for (Class class in selectedClasses) {
        [salt appendFormat:@"[%@ class],", NSStringFromClass(class)];
    }

    NSLog(@"Salt used (in this order): %@\n", salt);
    
    [self logCodeWithSuccessful:successful unsuccessful:unsuccessful];
#endif
    return YES;
}

+ (BOOL)generateCodeWithSaltUnsafe:(NSString *)salt WithStrings:(NSArray *)strings silence:(BOOL)silence successfulP:(NSMutableArray **)successfulP unsuccessfulP:(NSMutableArray **)unsuccessfulP;
{
#ifdef DEBUG
    // Function will return YES if process was successful in obfuscating ALL provided strings.
    // If even 1 string was not possible to obfuscate, then function will return NO.
    BOOL allSuccess = YES;
    
    //Store Successful and Unsuccessful Obfuscations
    NSMutableArray *successful = (successfulP == nil) ? [[NSMutableArray alloc] init] : *successfulP;
    NSMutableArray *unsuccessful = (unsuccessfulP == nil) ? [[NSMutableArray alloc] init] : *unsuccessfulP;
    
    Obfuscator *o = [Obfuscator newWithSaltUnsafe:salt];
    
    //Loop through list of strings
    for (id string in strings) {
        
        if ([string isKindOfClass:[NSString class]])
        {
            NSString *result = [o hexByObfuscatingString:string silence:YES];
            if (result == nil) //Unsuccessful
            {
                [unsuccessful addObject:string];
                allSuccess = NO;
            }
            else
            {
                [successful addObject:@{@"original": string, @"obfuscated": result}];
            }
        }
        else if ([string isKindOfClass:[NSDictionary class]])
        {
            NSString *result = [o hexByObfuscatingString:[string objectForKey:@"string"]
                                                 silence:YES];
            if (result == nil) //Unsuccessful
            {
                [unsuccessful addObject:[string objectForKey:@"string"]];
                allSuccess = NO;
            }
            else
            {
                [successful addObject:@{@"original": string[@"string"], @"key": string[@"id"], @"obfuscated": result}];
            }
        }
    }
    
    if (silence == NO)
    {
        [self logCodeWithSuccessful:successful unsuccessful:unsuccessful];
    }

    return allSuccess;
#endif
    return YES;
}

#pragma mark - Helper Functions

/*!
 * @brief Hashes salt using SHA1 algorithm.
 * @param salt Salt used for Obfuscation technique
 * @return NSString containing SHA1 hash of salt
 */
+ (NSString *)hashSaltUsingSHA1:(NSString *)salt
{
    NSData *d = [salt dataUsingEncoding:NSUTF8StringEncoding];
    
    // Get the SHA1 of a class name, to form the obfuscator.
    unsigned char obfuscator[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(d.bytes, (CC_LONG)d.length, obfuscator);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", obfuscator[i]];
    }
    
    return [output copy];
}


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

+ (NSString *)printHex:(NSString *)string
{
    return [self printHex:string WithKey:nil];
}

/*!
 * @brief Generates the Objective-C Code to define and initialize a global C-String (initialized in hexadecimal).
 * @discussion Hard-coded NSString objects are easily discoverable when using a jail-broken iPhone.
 * It is better to obfuscate the desired strings as C-Strings initialized in hexadecimal notation.
 * @param string A string that you wish to hardcode in your app as a C-String.
 * @param key The name of the generated C-Array that refers to the C-String.
 * @return Objective-C code to embed in your app to define and initialize a global C-String.
 */
+ (NSString *)printHex:(NSString *)string WithKey:(NSString *)key
{
    if (key == nil)
        key = @"key";
    
    NSMutableString *temp = [[NSMutableString alloc] initWithString:
                             [[NSString alloc] initWithFormat:@"const unsigned char _%@[] = { ",key]];

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

+ (void) logCodeWithSuccessful:(NSArray *)successful unsuccessful:(NSArray *)unsuccessful
{
    // Print out unsuccessful strings
    if ([unsuccessful count] != 0)
    {
        NSMutableString *final = [[NSMutableString alloc] initWithString:@"Could not obfuscate these strings:\n"];
        for (NSString *u in unsuccessful) {
            [final appendFormat:@"%@\n", u];
        }
        NSLog(@"%@-------------------------------", final);
    }
    
    
    //Print out Objective-C code for successful strings
    if ([successful count] != 0)
    {
        NSMutableString *header = [[NSMutableString alloc] initWithString:@""];
        NSMutableString *implementation = [[NSMutableString alloc] initWithString:@""];
        
        for (NSDictionary *s in successful) {
            NSString *key = [s objectForKey:@"key"];
            if (key == nil)
            {
                [header appendFormat:@"extern const unsigned char *key;\n"];
                [implementation appendFormat:@"//Original: \"%@\"\n%@\nconst unsigned char *key = &_%@[0];\n\n", s[@"original"], [self printHex:s[@"obfuscated"]], @"key"];
            }
            else{
                [header appendFormat:@"extern const unsigned char *%@;\n", key];
                [implementation appendFormat:@"//Original: \"%@\"\n%@\nconst unsigned char *%@ = &_%@[0];\n\n",s[@"original"],[self printHex:s[@"obfuscated"] WithKey:s[@"key"]],key,key];
            }
        }
        
        //Header and Implentation file
        NSLog(@"Objective-C Code:\n**********Globals.h**********\n%@\n**********Globals.m**********\n%@", header, implementation);
    }
}


/*!
 * @brief Concats a list of class names into a string.
 * @param classes An NSArray which contains a list of Classes of type Class.
 * e.g. [NSString class]
 */
+ (NSString *) stringFromClasses:(NSArray *)classes
{
    NSMutableString *finalString = [[NSMutableString alloc] initWithString:@""];
    
    for (id class in classes) {
        [finalString appendString:NSStringFromClass(class)];
    }
    
    return [finalString copy];
}


/*!
 * @brief Generates all permutations of contents of array.
 */
+ (NSArray *) allPermutationsOfArray:(NSArray*)array
{
    NSMutableArray *permutations = [NSMutableArray new];
    
    for (int i = 0; i < array.count; i++) { // for each item in the array
        if (permutations.count == 0) { // first time only
            
            for (id item in array) { // create a 2d array starting with each of the individual items
                NSMutableArray* partialList = [NSMutableArray arrayWithObject:item];
                [permutations addObject:partialList]; // where array = [1,2,3] permutations = [ [1] [2] [3] ] as a starting point for all options
            }
            
        } else { // second and remainder of the loops
            
            NSMutableArray *permutationsCopy = [permutations mutableCopy]; // copy the original array of permutations
            [permutations removeAllObjects]; // remove all from original array
            
            for (id item in array) { // for each item in the original list
                
                for (NSMutableArray *partialList in permutationsCopy) { // loop through the arrays in the copy
                    
                    if ([partialList containsObject:item] == false) { // add an item to the partial list if its not already
                        
                        // update a copy of the array
                        NSMutableArray *newArray = [NSMutableArray arrayWithArray:partialList];
                        [newArray addObject:item];
                        
                        // add to the final list of permutations
                        [permutations addObject:newArray];
                    }
                }
            }
        }
    }
    
    return [permutations copy];
}
@end
