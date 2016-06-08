//
//  BKSocialManager.m
//  Cryptoquips
//
//  Created by Andrew King on 2014-08-02.
//
//

#import "BKSocialManager.h"
#import "Reachability.h"
#import <Social/Social.h>

//#import "FBDialog.h"
//#import <FacebookSDK/FBDialogs.h>
//#import <Twitter/Twitter.h>


// Sharing Constants
//TODO: move these to their own class?

#define kCompletionGesture @"completionGesture"
#define kCompletionGestureCancel @"cancel"
#define kCompletionGesturePost  @"post"


@implementation BKTwitterParams

- (instancetype)initWithText:(NSString*)text {
    return [self initWithText:text link:nil image:nil];
}

- (instancetype)initWithText:(NSString *)text link:(NSURL *)link {
    return [self initWithText:text link:link image:nil];
}

- (instancetype)initWithText:(NSString *)text image:(UIImage*)image {
    return [self initWithText:text link:nil image:image];
}

- (instancetype)initWithText:(NSString *)text link:(NSURL *)link image:(UIImage *)image {
    if ((self = [super init])) {
        self.image = image;
        self.text = text;
        self.link = link;
    }
    return self;
}

@end


/**
 * BKSharing Manager
 * - Serves as an interface for Facebook, Twitter, Email, and Instagram.
 */
@implementation BKSocialManager

+ (id)sharedSocialManager {
    static BKSocialManager *socialManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        socialManager = [[self alloc] init];
    });
    return socialManager;
}

- (id)init {
    if (self = [super init]) {
        // Custom Init
    }
    return self;
}

#pragma mark - 
#pragma mark - Facebook

- (void)presentFacebookLoginDialogInView:(UIView *)presentingView {
    FBLoginView *loginView = [[FBLoginView alloc] init];
    // Align the button in the center horizontally
    loginView.frame = CGRectOffset(loginView.frame, (presentingView.center.x - (loginView.frame.size.width / 2)), 5);
    [presentingView addSubview:loginView];
}

/*
 NOTE: pre-filling fields associated with Facebook posts, unless the user manually generated the content earlier
 in the workflow of your app, can be against the Platform policies: https://developers.facebook.com/policy
 */
- (void)presentFacebookShareDialogWithAPIParams:(NSDictionary *)params {
    
    // Throw an Exception if there are no params
    if (!params) {
        NSDictionary *info = @{kErrorCode:  kErrorCodeFBShareParamsAreNil,
                               kErrorDesc:  kErrorDescFBShareParamsAreNil,
                               kErrorSrc:   [NSString stringWithFormat:@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__]};
        @throw [NSException exceptionWithName:@"Facebook Share Failed" reason:@"params were nil" userInfo:info];
    }
    
    // Make the request
    [FBRequestConnection startWithGraphPath:@"/me/feed" parameters:params HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (error) {
                                  // Handle error. See: https://developers.facebook.com/docs/ios/errors
                                  if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidFailWithError:)]) {
                                      [self.facebookShareDialogDelegate facebookShareDialogDidFailWithError:error];
                                  }
                                  NSLog(@"%@", error.description);
                              } else {
                                  // Link posted successfully to Facebook
                                  [self.facebookShareDialogDelegate facebookShareDialogDidFinishWithSuccessParams:nil];
                                  NSLog(@"result: %@", result);
                              }
                          }];
}

- (void)presentFacebookShareDialogWithLinkShareParams:(FBLinkShareParams *)linkParams{
    
    // Throw an exception if there is no link
    if (!linkParams.link) {
        NSDictionary *info = @{kErrorCode:  kErrorCodeFBShareLinkIsNil,
                               kErrorDesc:  kErrorDescFBShareLinkIsNil,
                               kErrorSrc:   [NSString stringWithFormat:@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__]};
        @throw [NSException exceptionWithName:@"Facebook Share Failed" reason:@"Link was nil" userInfo:info];
    }
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentShareDialogWithParams:linkParams]) {
        [FBDialogs presentShareDialogWithParams:linkParams
                                    clientState:nil
                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                            if(error) {
                                                NSLog(@"Error publishing story: %@", error.description);
                                                if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidFailWithError:)]) {
                                                    [self.facebookShareDialogDelegate facebookShareDialogDidFailWithError:error];
                                                }
                                            } else if ([results[kCompletionGesture] isEqualToString:kCompletionGestureCancel]) {
                                                NSLog(@"User cancelled story");
                                                if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidCancel)]) {
                                                    [self.facebookShareDialogDelegate facebookShareDialogDidCancel];
                                                }
                                            } else if ([results[kCompletionGesture] isEqualToString:kCompletionGesturePost]) {
                                                NSLog(@"User published story: %@", results);
                                                [self.facebookShareDialogDelegate facebookShareDialogDidFinishWithSuccessParams:results];
                                            }
                                        }];
    } else {
        NSDictionary *params = @{BKSocialFBApiParamName:         linkParams.name,
                                 BKSocialFBApiParamLink:         linkParams.link.absoluteString,
                                 BKSocialFBApiParamCaption:      linkParams.caption,
                                 BKSocialFBApiParamDescription:  linkParams.linkDescription,
                                 BKSocialFBApiParamPicture:      linkParams.picture.absoluteString};
        
        // Show the feed dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          NSLog(@"Error publishing story: %@", error.description);
                                                          if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidFailWithError:)]) {
                                                              [self.facebookShareDialogDelegate facebookShareDialogDidFailWithError:error];
                                                          }
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              NSLog(@"User cancelled.");
                                                              if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidCancel)]) {
                                                                  [self.facebookShareDialogDelegate facebookShareDialogDidCancel];
                                                              }
                                                          } else {
                                                              // Handle the publish feed callback
                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                              
                                                              if (![urlParams valueForKey:@"post_id"]) {
                                                                  NSLog(@"User cancelled.");
                                                                  if ([self.facebookShareDialogDelegate respondsToSelector:@selector(facebookShareDialogDidCancel)]) {
                                                                      [self.facebookShareDialogDelegate facebookShareDialogDidCancel];
                                                                  }
                                                              } else {
                                                                  // User clicked the Share button
                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                  NSLog(@"result %@", result);
                                                                  [self.facebookShareDialogDelegate facebookShareDialogDidFinishWithSuccessParams:urlParams];
                                                              }
                                                          }
                                                      }
                                                  }];
    }
}

- (void)presentFacebookRequestDialog {
    
    // Display the requests dialog
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:BKSocialFBRequestMessage
                                                    title:BKSocialFBRequestTitle
                                               parameters:nil
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          NSLog(@"Error sending request.");
                                                          if ([self.facebookRequestDialogDelegate respondsToSelector:@selector(facebookRequestDialogDidFailWithError:)]) {
                                                              [self.facebookRequestDialogDelegate facebookRequestDialogDidFailWithError:error];
                                                          }
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              NSLog(@"User clicked the \"x\". Cancelled request.");
                                                              if ([self.facebookRequestDialogDelegate respondsToSelector:@selector(facebookRequestDialogDidCancel)]) {
                                                                  [self.facebookRequestDialogDelegate facebookRequestDialogDidCancel];
                                                              }
                                                          } else {
                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                              NSLog(@"Facebook Completed with Params:%@", urlParams);
                                                              
                                                              if (![urlParams valueForKey:@"request"]) {
                                                                  NSLog(@"User canceled request.");
                                                                  if ([self.facebookRequestDialogDelegate respondsToSelector:@selector(facebookRequestDialogDidCancel)]) {
                                                                      [self.facebookRequestDialogDelegate facebookRequestDialogDidCancel];
                                                                  }
                                                              } else {
                                                                  NSString *requestID = [urlParams valueForKey:@"request"];
                                                                  NSLog(@"Request ID: %@", requestID);
                                                                  [self.facebookRequestDialogDelegate facebookRequestDialogDidFinishWithSuccessParams:urlParams];
                                                              }
                                                          }
                                                      }
     }];
}

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    return wasHandled;
}

+ (NSInteger)numberOfInvitesInSuccessParams:(NSDictionary *)params {
    int numInvites = 0;
    for (NSString *key in params.allKeys) {
        if ([key rangeOfString:@"to"].location != NSNotFound) {
            numInvites++;
        }
    }
    return numInvites;
}


#pragma mark - FBLoginViewDelegate Methods

// This method will be called when the user information has been fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    //self.profilePictureView.profileID = user.id;
    //self.nameLabel.text = user.name;
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // Did Login
    //self.statusLabel.text = @"You're logged in as";

}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // Did Logout
    //self.profilePictureView.profileID = nil;
    //self.nameLabel.text = @"";
    //self.statusLabel.text= @"You're not logged in!";
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // Error
    NSString *alertTitle;
    NSString *alertMessage;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}




#pragma mark -
#pragma mark - Twitter

- (void)presentTwitterTweetDialogFromViewController:(UIViewController *)presentingViewController withTwitterParams:(BKTwitterParams *)params {
    
    SLComposeViewController *tweeter = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    //TWTweetComposeViewController *tweeter = [[TWTweetComposeViewController alloc] init];
    [tweeter setInitialText:params.text];
    
    // Attempt to add url
    if (params.link) {
        [tweeter addURL:params.link];
    } else {
        [tweeter addURL:[NSURL URLWithString:kURLForAppInAppStoreTwitterRedirect]];
    }
    // Attempt to add image
    if (params.image) {
        [tweeter addImage:params.image];
    }

    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter] && (reachability.currentReachabilityStatus == ReachableViaWiFi || reachability.currentReachabilityStatus == ReachableViaWWAN)) {
        
        SLComposeViewControllerCompletionHandler completionHandler = ^(SLComposeViewControllerResult result) {
            
            [tweeter dismissViewControllerAnimated:YES completion:nil];
            if (result == SLComposeViewControllerResultDone) {
                [self.twitterTweetDialogDelegate twitterDidSucceedWithParams:params];
            } else if (result == SLComposeViewControllerResultCancelled) {
                [self.twitterTweetDialogDelegate twitterDidCancelWithParams:params];
            }
        };
        [tweeter setCompletionHandler:completionHandler];
//        [presentingViewController.navigationController pushViewController:tweeter animated:YES];
        [presentingViewController presentViewController:tweeter animated:YES completion:nil];
    } else {
        [self.twitterTweetDialogDelegate twitterDidFailWithParams:params];
    }
    
}


//#pragma mark -
//#pragma mark - Email
//- (void)presentEmailDialogInView:(UIView *)presentingView {
//    
//}

//#pragma mark -
//#pragma mark - Instagram
//- (void)presentInstagramShareDialogInView:(UIView *)presentingView {
//    
//}

@end
