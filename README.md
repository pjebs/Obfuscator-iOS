App Obfuscator for iOS Apps
============================

Secure your app by obfuscating all the hard-coded security-sensitive strings.

Security Sensitive strings can be:

* REST API Credentials
* OAuth Credentials
* Passwords
* URLs not intended to be known to the public (i.e. private backend API endpoints)
* Keys & Secrets

This library hard-codes typical NSStrings as C language strings by obfuscating and then encoding as hexadecimal.
When your app needs the original unobfuscated NSStrings, it dynamically decodes it back.

It adds an extra layer of security against prying eyes.

This makes it harder for people with jail-broken iPhones from opening up your app's executable file and 
then looking for strings embedded in the binary that may appear 'interesting'.

See generally:
* [iOS App Security and Analysis](http://www.raywenderlich.com/46223/ios-app-security-analysis-part-2)
* [Storing Secret Keys](http://www.splinter.com.au/2014/09/16/storing-secret-keys/)

This library (v2+) can now be bridged over to Swift.

Installation
-------------

### CocoaPods

pod 'Obfuscator', '~> 2.0'

### Create Globals.h & Globals.m files

This is typically where you store your sensitive strings that you want available globally.

File(top menu)->New->File...

### Create a Prefix Header

For XCode 6, you will need to create a `pch` file [from scratch](http://stackoverflow.com/questions/24158648/why-isnt-projectname-prefix-pch-created-automatically-in-xcode-6).

- Add to bottom:

```objective-c
//Now you do not need to include those headers anywhere else in your project.
#import "Globals.h"
#import <Obfuscator/Obfuscator.h>
```

Usage
-----

### Step 1

Let's assume you are using [Parse](https://parse.com/). In order to use their backend services, they will provide you with a client key:

```objective-c
clientKey:@"JEG3i8R9LAXIDW0kXGHGjauak0G2mAjPacv1QfkO"
```

Since the string is hard-coded, it will be baked into the executable binary - easily accessible to unscrupulous prying eyes.

We need to encode it as a global C-String encoded in hexadecimal.

```objective-c
Obfuscator *o = [Obfuscator newWithSalt:[AppDelegate class],[NSString class], nil];  //Use any class(es) within your app that won't stand out to a hacker

[o hexByObfuscatingString:@"JEG3i8R9LAXIDW0kXGHGjauak0G2mAjPacv1QfkO"];
```

This will print out the following code in the XCode Console output (`NSLog`):

```objective-c
Objective-C Code:
extern const unsigned char *key;
//Original: JEG3i8R9LAXIDW0kXGHGjauak0G2mAjPacv1QfkO
const unsigned char _key[] = { 0x7E, 0x23, 0x25, 0xB, 0xB, 0xF, 0x31, 0x9, 0x7B, 0x70, 0x3B, 0x7F, 0x21, 0x35, 0x9, 0x52, 0x6D, 0x21, 0x2C, 0x7F, 0xE, 0x4, 0x43, 0x52, 0x53, 0x54, 0x75, 0x4, 0x5C, 0x27, 0xB, 0x36, 0x3, 0x5B, 0x15, 0x52, 0x60, 0x5E, 0xE, 0x2E, 0x00 };
const unsigned char *key = &_key[0];
```

**Before Deploying your app DELETE OUT ALL REFERENCE TO `hexByObfuscatingString:` METHOD.** It is purely for obtaining the Objective-C code above.


### Step 2

Copy the `extern const unsigned char *key;` from **Step 1** into `Globals.h`.

Copy the `const unsigned char *_key[] = ...` from **Step 1** into `Globals.m`.

Copy the `const unsigned char *key = &_key[0];` from **Step 1** into `Globals.m`.

Remember to change `key` to something more meaningful such as `parseKey`.

It may be a good idea to add the original string as comments in `Globals.m` in case you need to re-encode it again (i.e. Step 4).

### Step 3

When your app needs to use the unobfuscated string:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	Obfuscator *o = [Obfuscator newWithSalt:[AppDelegate class],[NSString class], nil]; //The salt MUST match Step 1
	
	/* INSTEAD OF THIS:
	[Parse setApplicationId:@"TestApp"
              clientKey:@"JEG3i8R9LAXIDW0kXGHGjauak0G2mAjPacv1QfkO"];
	 */


	[Parse setApplicationId:@"TestApp"
              	clientKey:[o reveal:parseKey];

	return YES;
}
```

**The Salt used by `reveal:` method MUST MATCH the salt used in Step 1.**

### Step 4

**THIS STEP IS VERY IMPORTANT**

Double check that **ALL** of your obfuscated strings can be unobfuscated back to the original. If not, then change the salt and try again.
If even one string cannot be unofuscated, then that *particular* string can not be used with this library. The others can.

More Advanced Usage
--------------------

### Step 1 - Generate Objective-C Code

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
    [Obfuscator generateCodeWithSalt:@[[NSString class], [AppDelegate class], [NSObject class]]
                         WithStrings:@[
                                       @{@"id": @"AA", @"string":@"testSecret"},
                                       @{@"id": @"BB", @"string":@"testKey"},
                                       @{@"id": @"CC", @"string":@"parseKey1234"},
                                       ]];


	return YES;
}
```

This will output:

```objective-c
Salt used (in this order): [AppDelegate class],[NSObject class],[NSString class],

Objective-C Code:
**********Globals.h**********
extern const unsigned char *AA;
extern const unsigned char *BB;
extern const unsigned char *CC;

**********Globals.m**********
//Original: "testSecret"
const unsigned char _AA[] = { 0x41, 0x51, 0x46, 0x44, 0x62, 0x52, 0x55, 0x44, 0x3, 0x4C, 0x00 };
const unsigned char *AA = &_AA[0];

//Original: "testKey"
const unsigned char _BB[] = { 0x41, 0x51, 0x46, 0x44, 0x7A, 0x52, 0x4F, 0x00 };
const unsigned char *BB = &_BB[0];

//Original: "parseKey1234"
const unsigned char _CC[] = { 0x45, 0x55, 0x47, 0x43, 0x54, 0x7C, 0x53, 0x4F, 0x57, 0xA, 0x56, 0x56, 0x00 };
const unsigned char *CC = &_CC[0];
```

Copy and Paste the generated code.

**NB: The Salt has been rearranged because the original arrangement was not able to obfuscate all 3 strings.**

The Algorithm will go through all permutations of `Salt` to maximize the number of strings it was able to obfuscate.
Sometimes it will not succeed completely, so the output will indicate which strings were not obfuscated. For the unobfuscated strings, try a totally different salt OR add more classes to the salt list and try again. The more classes you add, the better chance of obfuscating all strings.

**DELETE OUT [Obfuscator generateCodeWithSalt:WithStrings:] for production.**

### Step 2 - Store Salt in key-value internal database

```objective-c
[Obfuscator storeKey:@"swift" forSalt:[AppDelegate class],[NSObject class],[NSString class], nil];
```

If your project is written in Objective-C, there are other undocumented ways to proceed after Step 1. However, this is the only way to proceed
for a Swift based project. This way will work in both Swift and Objective-C.

**NB: The Salt list applied to `storeKey:forSalt:` must be ordered according to the output in Step 1. This arrangement may be different to the argument applied to `generateCodeWithSalt:WithStrings:`.

You can use different keys to identify different salts if you choose to obfuscate multiple strings using different salts.


### Step 3 - Dynamically decode obfuscated string when you need to use it.


```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
		
	/* INSTEAD OF THIS:
	[Parse setApplicationId:@"TestApp"
              clientKey:@"JEG3i8R9LAXIDW0kXGHGjauak0G2mAjPacv1QfkO"];
	 */


	[Parse setApplicationId:@"TestApp"
              	clientKey:[Obfuscator reveal:CC UsingStoredSalt:@"swift"];

	return YES;
}
```

For swift:

```swift
	Obfuscator.reveal(CC, usingStoredSalt: "swift")
```


Other Useful Packages
------------

Check out [`"github.com/pjebs/EasySocial"`](https://github.com/pjebs/EasySocial) library. The Easiest and Simplest iOS library for Twitter and Facebook. Just Drop in and Use!


Check out [`"github.com/pjebs/optimus-go"`](https://github.com/pjebs/optimus-go) package. Internal ID hashing and Obfuscation using Knuth's Algorithm. (For databases etc)

Credits: 
--------

* [Storing Secret Keys](http://www.splinter.com.au/2014/09/16/storing-secret-keys/)
* [Obfuscation Encryption of String NSString](http://iosdevelopertips.com/cocoa/obfuscation-encryption-of-string-nsstring.html)
* [Creating SHA1 Hash from NSString](http://stackoverflow.com/questions/7570377/creating-sha1-hash-from-nsstring)

Final Notes
------------

If you found this package useful, please **Star** it on github. Feel free to fork or provide pull requests. Any bug reports will be warmly received.


[PJ Engineering and Business Solutions Pty. Ltd.](http://www.pjebs.com.au)