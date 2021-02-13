//
//  Obfuscator.h
//
//  Created by PJ on 11/07/2015.
//  Copyright (c) 2015 PJ Engineering and Business Solutions Pty. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Code based on these articles/code-samples:
 * http://www.splinter.com.au/2014/09/16/storing-secret-keys/
 * http://iosdevelopertips.com/cocoa/obfuscation-encryption-of-string-nsstring.html
 * http://stackoverflow.com/questions/7570377/creating-sha1-hash-from-nsstring
 * http://stackoverflow.com/questions/3791265/generating-permutations-of-nsarray-elements
 */
@interface Obfuscator : NSObject

    /*!
     * @brief DO NOT USE!
     * @discussion Do not use unless you know what you are doing!
     * The aim is to not use ANY hard-coded string values when obfuscating security-sensitive strings.
     * The string used SHOULD BE dynamically generated and always the same everytime you run your app.
     * The string used SHOULD APPEAR like a 'normal' 'mundane' string that does not hold sensitive data.
     * @warning DO NOT USE! For internal use only.
     */
    + (instancetype)newWithSaltUnsafe:(NSString *)string;

    /*!
     * @brief Create Obfuscator class with the salt required to unobfuscate hard-coded C-Strings.
     * @discussion Hard-Coded NSString objects are easily discoverable if you have a jail-broken iPhone.
     * It is better to obfuscate the security-sensitive strings (such as REST API/OAUTH Credentials, important URL's etc.)
     * and dynamically convert them to the original NSString at run-time before you need to use them.
     *
     * Although referred to as salt, it is not actually a 'salt' in the crypto context.
     *
     * See: http://www.raywenderlich.com/46223/ios-app-security-analysis-part-2
     * See: http://www.splinter.com.au/2014/09/16/storing-secret-keys/
     * @param class A class object that should NOT appear 'interesting' (as strings embedded in the source-code) to prying eyes. Do not use [Obfuscator class].
     * @warning The salt used to obfuscate must be exactly the same for reveal to work.
     * @return Obfuscator class instance.
     */
    + (instancetype)newWithSalt:(Class)class, ... NS_REQUIRES_NIL_TERMINATION;

    /*!
     * @brief Create Obfuscator class using salts stored in key-value database.
     * @discussion If you use multiple salts for different obfuscated strings, you can store them in an
     * internal key-value database.
     * Since `+ (instancetype)newWithSalt:(Class)class, ...` does not get bridged over to Swift, the only 
     * way to use this library in Swift is by storing salts using `+ (void) storeKey:(NSString *)key forSalt:(Class)class, ...`.
     * @param key Key used to pull the desired salt from key-value database.
     * @warning warning description
     * @return Obfuscator class instance.
     */
    + (instancetype)newUsingStoredSalt:(NSString *)key;

    /*!
     * @brief Converts obfuscated hard-coded C-String back to original string during run-time.
     * @discussion Hard-Coded NSString objects are easily discoverable if you have a jail-broken iPhone.
     * It is better to obfuscate the security-sensitive strings (such as REST API/OAUTH Credentials, important URL's etc.)
     * and dynamically convert them to the original NSString at run-time before you need to use them.
     *
     * See: http://www.raywenderlich.com/46223/ios-app-security-analysis-part-2
     * See: http://www.splinter.com.au/2014/09/16/storing-secret-keys/
     * @param string Obfuscated C-String which needs to be converted back to original.
     * @warning The salt used to obfuscate must be exactly the same for reveal to work.
     * @return Original NSString which you can use for REST API Authenitcation, URL's etc.
     */
    - (NSString *)reveal:(const unsigned char *)string;

    /*!
     * @brief Generates Objective-C code for obfuscating security-sensitive string.
     * @discussion The desired string that you wish to obfuscate needs to be hard-coded as a C-language string.
     * This method generates the hexadecimal literals to embed in your source-code.
     * Logs the generated code to the console output.
     * Use the reveal: method to unobfuscate in order to use within your app.
     * @param string Security-Sensitive string that you wish to obfuscate.
     * @warning Use this only during Development. Remove all references to this method before deployment.
     * @return For internal use only.
     */
    - (NSString *)hexByObfuscatingString:(NSString *)string;

    /*!
     * @brief DO NOT USE!
     * @discussion Do not use unless you know what you are doing!
     * Generates Objective-C header and implementation code for multiple strings.
     * @param strings NSArray filled with NSStrings representing strings you wish to obfuscate OR
     * NSDictionary(-ies) with the details of the variable name and strings you wish to obfuscate.
     * @warning DO NOT USE! For internal use only.
     */
    + (BOOL)generateCodeWithSaltUnsafe:(NSString *)salt WithStrings:(NSArray *)strings;

    /*!
     * @brief Generates Objective-C code for obfuscating multiple security-sensitive string.
     * @discussion Generates Objective-C header and implementation code for multiple strings.
     * This is the recommended method to obfuscate all your security-sensitive strings.
     * Logs the generated code to the console output.
     * Be mindful that some strings will be not be obfuscateable. This will be notified in the output.
     * If that is the case, add some more classes to the salt.
     * Be mindful that the order in the list of classes may get rearranged. This will also be notified.
     * The order is important for unobfuscating!
     * @param classes An NSArray of Classes used to generate the salt, which is then used to obfuscate
     * the list of strings. eg. @[ [NSString class], [NSObject class]...]
     * @param strings NSArray filled with NSStrings representing strings you wish to obfuscate OR
     * NSDictionary(-ies) with the details of the variable name and strings you wish to obfuscate.
     * @warning Do not use from within Swift Code. Use it only from Objective-C code since (NSArray *)classes
     * must contain Class objects which are not supported in Swift. The generated code will by useable from
     * Swift however.
     * The order in the list of classes may get rearranged. The order is important for unobfuscating!
     * @return For internal use only.
     * @code
     NSArray *salts = @[[AppDelegate class], [NSObject class], [NSString class]];
     NSArray *strings = @[
                            @{@"id": @"awsKey", @"string": @"123456ABC"},
                            @{@"id": @"parseKey", @"string": @"98765DEF"},
                        ];
     [Obfuscator generateCodeWithSalt:salts WithStrings:strings];
     */
    + (BOOL)generateCodeWithSalt:(NSArray *)classes WithStrings:(NSArray *)strings;

    /*!
     * @brief Stores Salt(s) in an internal key-value database.
     * @discussion You may want to use different salts for different strings. This class method provides
     * convenience. 
     * In order to use this library from within Swift code, you MUST use this library to store the salts used
     * to obfuscate your strings. You must use it from within your Objective-C code however.
     * @param class List of classes to be used as salt. i.e. [NSString class], [NSObject class]...
     * @param key The key associated with the list of classes in key-value database.
     * @warning Does not get bridged to Swift. Use from within Objective-C code so that the salts will become
     * available to Swift code by using: `+ (NSString *)reveal:UsingStoredSalt:` or `+ (instancetype)newUsingStoredSalt:`.
     */
    + (void)storeKey:(NSString *)key forSalt:(Class)class, ... NS_REQUIRES_NIL_TERMINATION;

    /*!
     * @brief Converts obfuscated hard-coded C-String back to original string during run-time.
     * @discussion Uses salt stored in internal key-value database to unobfuscate.
     * @param string string you wish to unobfuscate.
     * @param key key representing the salt stored in internal key-value database
     * @warning Can be used in Swift along with `- (NSString *)reveal:`.
     * @return Original NSString which you can use for REST API Authenitcation, URL's etc.
     */
    + (NSString *)reveal:(const unsigned char *)string UsingStoredSalt:(NSString *)key;

@end
