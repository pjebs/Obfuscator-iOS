//
//  Obfuscator.h
//
//  Created by PJ on 15/06/2015.
//  Copyright (c) 2015 PJ Engineering and Business Solutions Pty. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonCrypto.h>

/*
 * Code based on these articles/code-samples:
 * http://www.splinter.com.au/2014/09/16/storing-secret-keys/
 * http://iosdevelopertips.com/cocoa/obfuscation-encryption-of-string-nsstring.html
 * http://stackoverflow.com/questions/7570377/creating-sha1-hash-from-nsstring
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
     * @return Objective-C code to embed in your app to define and initialize a global C-String.
     */
    - (NSString *)hexByObfuscatingString:(NSString *)string;

@end
