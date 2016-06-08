//
//  BKSocialManager.h
//  Cryptoquips
//
//  Created by Andrew King on 2014-08-02.
//
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#include "BKSharingConstants.h"
#import "constants.h"



#pragma mark - BKSocialFacebookRequestDialogDelegate

/**
 @brief This protocol should be implemented by any controller that uses the presentFacebookRequestDialog method. It allows the user to set handlers for the various states possible at the outcome of the request dialog: success, error, cancelled.
 
 @note The case where the user presses the 'x' or the 'cancel' button are both treated the same and handled with the didCancel method.
 */
@protocol BKSocialFacebookRequestDialogDelegate <NSObject>

/**
 @brief Called when the dialog completes successfully. The params are a dictionary returned in the params of the response url.
 */
- (void)facebookRequestDialogDidFinishWithSuccessParams:(NSDictionary *)params;

@optional

/**
 @brief Called when the dialog encounters an error.
 @see https://developers.facebook.com/docs/ios/errors for a list of errors and their meanings
 */
- (void)facebookRequestDialogDidFailWithError:(NSError *)error;

/**
 @brief Called if the user presses one of the 'x' or 'Cancel' buttons.
 */
- (void)facebookRequestDialogDidCancel;

@end



#pragma mark - BKSocialFacebookShareDialogDelegate

/**
 @brief This protocol should be implemented by any controller that uses the presentFacebookShareDialogWithAPIParams: or presentFacebookShareDialogWithLinkShareParams: methods. It allows the user to set handlers for the various states possible at the outcome of the request dialog: success, error, cancelled.
 
 @note The case where the user presses the 'x' or the 'cancel' button are both treated the same and handled with the didCancel method.
 */
@protocol BKSocialFacebookShareDialogDelegate <NSObject>

/**
 @brief Called when the dialog completes successfully. The params are a dictionary returned in the params of the response url.
 */
- (void)facebookShareDialogDidFinishWithSuccessParams:(NSDictionary *)params;

@optional

/**
 @brief Called when the dialog encounters an error.
 @see https://developers.facebook.com/docs/ios/errors for a list of errors and their meanings
 */
- (void)facebookShareDialogDidFailWithError:(NSError *)error;

/**
 @brief Called if the user presses one of the 'x' or 'Cancel' buttons.
 */
- (void)facebookShareDialogDidCancel;

@end

#pragma mark - BKTwitterParams

/**
 * Params passed into the twitter methods with possible attachments for tweets.
 */
@interface BKTwitterParams : NSObject

/**
 The text that will appear in the tweet
 */
@property (nonatomic, strong) NSString  *text;

/**
 The link that will be attached in the tweet
 */
@property (nonatomic, strong) NSURL     *link;

/**
 The image that will appear in the tweet
 */
@property (nonatomic, strong) UIImage   *image;

/**
 Initializes the params with tweet text
 */
- (instancetype)initWithText:(NSString*)text;

/**
 Initializes the params with tweet text and a link
 */
- (instancetype)initWithText:(NSString *)text link:(NSURL *)link;

/**
 Initializes the params with tweet text and an image
 */
- (instancetype)initWithText:(NSString *)text image:(UIImage*)image;

/**
 Initializes the params with tweet text, a link, and an image.
 */
- (instancetype)initWithText:(NSString *)text link:(NSURL *)link image:(UIImage *)image;

@end



#pragma mark - BKSocialTwitterTweetDialogDelegate

@protocol BKSocialTwitterTweetDialogDelegate <NSObject>

- (void)twitterDidSucceedWithParams:(BKTwitterParams *)params;

- (void)twitterDidFailWithParams:(BKTwitterParams *)params;

- (void)twitterDidCancelWithParams:(BKTwitterParams *)params;

@end



#pragma mark - BKSocialManager

/**
 * BKSharingManager is a Singleton used for sharing with Facebook, Twitter, Email, or Instagram.
 */
@interface BKSocialManager: NSObject <FBLoginViewDelegate>


/**
 * Sharing Manager shared instance.
 */
+ (id)sharedSocialManager;

/**
 Required to be set by any class that conforms to the BKSocialFacebookShareDialogDelegate protocol.
 */
@property (weak) id<BKSocialFacebookShareDialogDelegate> facebookShareDialogDelegate;

/**
 Required to be set by any class that conforms to the BKSocialFacebookRequestDialogDelegate protocol.
 */
@property (weak) id<BKSocialFacebookRequestDialogDelegate> facebookRequestDialogDelegate;

@property (weak) id<BKSocialTwitterTweetDialogDelegate>twitterTweetDialogDelegate;

///////////////
// FACEBOOK

/**
 * Facebook Login
 */
- (void)presentFacebookLoginDialogInView:(UIView *)presentingView;

/**
 * Facebook Share (API)
 */
- (void)presentFacebookShareDialogWithAPIParams:(NSDictionary *)params;

/**
 * Facebook Share (Native)
 * - defaults to iOS Native share, falls back to feed
 */
- (void)presentFacebookShareDialogWithLinkShareParams:(FBLinkShareParams *)params;

/**
 * Facebook Invite Friends (Native)
 */
- (void)presentFacebookRequestDialog;

/**
 * Handles opening app from a facebook deep link
 */
- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

+ (NSInteger)numberOfInvitesInSuccessParams:(NSDictionary *)params;


///////////////
// TWITTER

- (void)presentTwitterTweetDialogFromViewController:(UIViewController *)presentingViewController withTwitterParams:(BKTwitterParams *)params;



///////////////
// EMAIL
//- (void)presentEmailDialogInView:(UIView *)presentingView;

///////////////
// INSTAGRAM
//- (void)presentInstagramShareDialogInView:(UIView *)presentingView;

@end
