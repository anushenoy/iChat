//
//  ViewController.m
//  DemoMessaging
//
//  Created by atidan on 16/06/16.
//  Copyright © 2016 atidan. All rights reserved.
//

#import "ViewController.h"
#import "FirebaseDatabase/FirebaseDatabase.h"
#import "FirebaseAuth/FIRAuth.h"
#import "ChatViewController.h"


@interface ViewController ()
@property (nonatomic, strong)    FIRUser *userObj;
@end

@implementation ViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)loginPressed:(id)sender
{
    
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user,
                                                      NSError *_Nullable error) {
        if (error)
        {
            NSLog(@"Sign in failed: %@", error.localizedDescription);
        }
        else
        {
            _userObj = user;
            
            NSLog(@"Signed in with uid: %@", user.uid);
            
            [self performSegueWithIdentifier:@"LoginToChat" sender:self];
        }
    }];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if( [segue.identifier isEqualToString:@"LoginToChat"])
    {
        UINavigationController * navVc = [segue destinationViewController] ;
        ChatViewController * chatVc = [navVc.viewControllers firstObject] ;
        chatVc.senderId = _userObj.uid;
        chatVc.senderDisplayName = @"";
    }
    
}
@end
