#
#  Be sure to run `pod spec lint Obfuscator.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "Obfuscator"
  s.version      = "2.0.0"
  s.summary      = "Secure your app by obfuscating all the hard-coded security-sensitive strings."

  s.description  = <<-DESC
                   Secure your app by obfuscating all the hard-coded security-sensitive strings.

                   Security Sensitive strings can be:

                   * REST API Credentials
                   * OAuth Credentials
                   * Passwords
                   * URLs not intended to be known to the public (i.e. private backend API endpoints)
                   * Keys & Secrets

                   This library hard-codes typical NSStrings as C language strings encoded in hexadecimal.
                   When your app needs the original unobfuscated NSStrings, it dynamically decodes it back.

                   It adds an extra layer of security against prying eyes.

                   This makes it harder for people with jail-broken iPhones from opening up your app's executable file and 
                   looking for strings embedded in the binary that may appear 'interesting.'

                   See generally:
                   * http://www.raywenderlich.com/46223/ios-app-security-analysis-part-2
                   * http://www.splinter.com.au/2014/09/16/storing-secret-keys/

                   This library (v2+) can now be bridged over to Swift.

                   DESC

  s.homepage     = "https://github.com/pjebs/Obfuscator-iOS"

  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "PJ Engineering and Business Solutions Pty. Ltd." => "enquiries@pjebs.com.au" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/pjebs/Obfuscator-iOS.git", :tag => "v2.0.0" }
  s.source_files  = "Obfuscator/*"
  s.requires_arc = true

end