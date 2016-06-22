//
//  ChatViewController.m
//  DemoMessaging
//
//  Created by atidan on 17/06/16.
//  Copyright © 2016 atidan. All rights reserved.
//

#import "ChatViewController.h"
#import "FirebaseDatabase/FirebaseDatabase.h"
#import "FirebaseAuth/FIRAuth.h"
#import "JSQMessagesViewController/JSQMessagesViewController.h"
#import "JSQMessagesViewController/JSQMessagesBubbleImage.h"
#import "JSQMessagesViewController/JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesViewController/JSQMessage.h"
#import "JSQSystemSoundPlayer/JSQSystemSoundPlayer.h"


@import Firebase;

@interface ChatViewController ()
{
    FIRDatabaseHandle _msgHandle;
}
@property (nonatomic, strong) FIRDatabaseQuery *typingQuery;
@property (nonatomic, strong) FIRDatabaseReference *rootRef;
@property (nonatomic, strong) FIRDatabaseReference *isTypingRef;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleImageView;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleImageView;
@property (nonatomic) Boolean isTyping;
@end

@implementation ChatViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"iChat";
    
    [self setupBubbles];
    
    _messages = [[NSMutableArray alloc] init];

    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.inputToolbar.contentView.leftBarButtonItem = nil ;
    
    _rootRef= [[FIRDatabase database] reference];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];

}

-(void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    [self observeMessages];
    [self observeIsTyping];
  
}



- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Helpers

-(void)setupBubbles
{
    
    JSQMessagesBubbleImageFactory * factory = [[JSQMessagesBubbleImageFactory alloc ]init];
    
    _outgoingBubbleImageView = [factory outgoingMessagesBubbleImageWithColor:[UIColor colorWithHue:130.0f / 360.0f
                                                                                        saturation:0.68f
                                                                                        brightness:0.84f
                                                                                             alpha:1.0f]];
    
    _incomingBubbleImageView = [factory incomingMessagesBubbleImageWithColor:[UIColor colorWithHue:240.0f / 360.0f
                                                                                        saturation:0.02f
                                                                                        brightness:0.92f
                                                                                             alpha:1.0f]];
    
}

-(void)addMessagewithId:(NSString*) senderId andText:(NSString*) text
{
    
    JSQMessage* message = [JSQMessage messageWithSenderId:senderId displayName:@"" text:text];
    
    [_messages addObject:message];
    
}


-(void)observeMessages
{
    
    _msgHandle = [[_rootRef child:@"messages"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        NSDictionary<NSString *, NSString *> *message = snapshot.value;
        
        NSString *name = message[@"senderId"];
        NSString *text = message[@"text"];
        
        [self addMessagewithId:name andText:text];
        
        // animates the receiving of a new message on the view
        [self finishReceivingMessage];
    }];
    
    
}

-(void)observeIsTyping
{

    
    _isTypingRef = [[_rootRef child:@"isTypingIndicator"] child:self.senderId ];
    
    [_isTypingRef onDisconnectRemoveValue];
    
    _typingQuery = [[[_rootRef child:@"isTypingIndicator"] queryOrderedByValue] queryEqualToValue:@"1"];
    
    [_typingQuery observeEventType:FIRDataEventTypeValue withBlock:  ^ (FIRDataSnapshot *snapshot) {
        
        
        if ( snapshot.hasChildren)
        {
            if (snapshot.childrenCount == 1 && self.isTyping)
            {
                //  You're the only typing, don't show the indicator
                [self setShowTypingIndicator:NO];
            }
            else
            {
                //  others typing
                [self setShowTypingIndicator:YES];
            }
        }
        else
        {
            [self setShowTypingIndicator:NO];
        }
        
        [self scrollToBottomAnimated:YES];
    }];

}
-(void)sendIsTyping
{

    // Push data to Firebase Database
    if(_isTyping)
    {
        [_isTypingRef setValue:@"1"];
    }
    else
    {
        [_isTypingRef setValue:@"0"];
    }
   
}

#pragma mark - button actions

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{

    NSDictionary *mdata = @{@"text": text, @"senderId":senderId};

    // Push data to Firebase Database
    [[[_rootRef child:@"messages"] childByAutoId] setValue:mdata];
    
    //[JSQSystemSoundPlayer jsq__playMessageSentSound];
    
    _isTyping =false;
    [self sendIsTyping];
    [self finishSendingMessage];
    
    
   
    
}
- (IBAction)Logout:(id)sender
{

    FIRAuth *firebaseAuth = [FIRAuth auth];
    
    NSError *signOutError;
    
    BOOL status = [firebaseAuth signOut:&signOutError];
    
    if (!status)
    {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    
//    [AppState sharedInstance].signedIn = false;
    
    [self performSegueWithIdentifier:@"SeguesToSignIn"sender:nil];
    
}


#pragma mark - TextView
-(void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    
    _isTyping =  ![textView.text  isEqual: @""];
  
    [self sendIsTyping];

}

#pragma mark - CollectionView

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    return [_messages objectAtIndex:indexPath.row] ;
    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    return _messages.count;
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell*)[super  collectionView:collectionView cellForItemAtIndexPath:indexPath];
   
    JSQMessage * msg = [_messages objectAtIndex:indexPath.row] ;
    
    if ([msg.senderId isEqualToString: self.senderId] )
    {
        cell.textView.textColor = [UIColor whiteColor];
    }
    else
    {
        cell.textView.textColor = [UIColor blackColor];
    }
    
    return cell;

}

-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{

    JSQMessage * msg = [_messages objectAtIndex:indexPath.row] ;
    
    if ([msg.senderId isEqualToString: self.senderId] )
    {
        return _outgoingBubbleImageView;
    }
    else
    {
        return _incomingBubbleImageView;
    }

}

-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{

    return nil;
    
}

@end
