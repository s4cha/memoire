//
//  PurchaseHistoryViewController.m
//  Clubscore
//
//  Created by hhs-fueled on 28/05/13.
//  Copyright (c) 2013 Fueled Inc. All rights reserved.
//

#import "PurchaseHistoryViewController.h"
#import "PurchaseHistoryCell.h"
#import "PurchasedEventDetails.h"

#define kPurchaseHistoryNavBarTitle @"PurchaseHistory_Title"
#define kUpcomingButtonTitle @"PurchaseHistory_Upcoming"
#define kArchiveButtonTitle @"PurchaseHistory_Archive"
#define kNeedToDiscussLabel @"PurchaseHistory_NeedToDiscuss"
#define kContactYourConciergeButtonTitle @"PurchaseHistory_ContactYourConcierge"
#define kNoPurchaseHistoryLabelText @"PurchaseHistory_NoPurchaseHistory"
#define kNoPurchaseHistoryMessageLabelText @"PurchaseHistory_NoPurchaseHistoryMessage"
#define kStandardResultsPerPage [NSNumber numberWithInt:10]

#define kWeekSection 0
#define kMonthSection 1
#define kYearSection 2
#define kSectionHeaderHeight 45.0

//Url String paths
#define kUrlStringForUpcoming @"/reservations/mine/?apiMode=VIP&json=true&page=:currentPage&per_page=:perPage&sort_option=by_date&upcoming_only=true&archive_only=false"
#define kUrlStringForArchive @"/reservations/mine/?apiMode=VIP&json=true&page=:currentPage&per_page=:perPage&sort_option=by_date&upcoming_only=false&archive_only=true"

#define kContactYourConciergeSegue @"contactYourConciergeFromPurchaseHitory"

typedef enum {
  CSReservationTypeArchive = 1,
  CSReservationTypeUpcoming = 2,
} CSReservationType;

@interface PurchaseHistoryViewController ()<UITableViewDataSource, UITableViewDelegate, PurchasedEventDetailsDelegate, PurchaseHistoryCellDelegate>

@property (weak, nonatomic) IBOutlet UIButton *upcomingButton;
@property (weak, nonatomic) IBOutlet UIButton *archiveButton;


@property (weak, nonatomic) IBOutlet UIView *eventsPurchasedView;
@property (weak, nonatomic) IBOutlet UILabel *needToDiscussLabel;
@property (weak, nonatomic) IBOutlet UIButton *contactYourConciergeButton;
@property (weak, nonatomic) IBOutlet UITableView *eventsPurchasedTableView;

@property (weak, nonatomic) IBOutlet UIView *noEventsPurchasedView;
@property (weak, nonatomic) IBOutlet UILabel *noPurchaseHistoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *noPurchaseHistoryMessageLabel;

@property (strong, nonatomic) NSMutableArray * eventsPurchased;
@property (strong, nonatomic) PurchasedEventDetails * purchasedEventDetailsView;

@property (strong, nonatomic) NSNumber *lastUpcomingCallPage;
@property (strong, nonatomic) NSNumber *lastArchiveCallPage;

@property (strong, nonatomic) NSMutableArray *eventsPurchasedUpcoming;
@property (strong, nonatomic) NSMutableArray *eventsPurchasedArchived;

@property (nonatomic,strong) NSIndexPath *currentIndexPath;
@property (nonatomic,strong) NSIndexPath *previousIndexPath;

@property (nonatomic, assign) CSReservationType reservationType;

//Properties required for pagination
@property (nonatomic,strong) RKPaginator *paginator;
@property (nonatomic,strong) NSMutableArray *objects;

@property (nonatomic, strong) NSMutableArray *eventsPurchasedArchivedWeek;
@property (nonatomic, strong) NSMutableArray *eventsPurchasedArchivedMonth;
@property (nonatomic, strong) NSMutableArray *eventsPurchasedArchivedYear;

@property (nonatomic,assign) BOOL isPaginatorLoading;

@end

@implementation PurchaseHistoryViewController

@synthesize reservationType = _reservationType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
  
  [self setupNavigationBarWithBackButtonAndTitle:NSLocalizedString(kPurchaseHistoryNavBarTitle, @"").uppercaseString];

  [self setTextAndFont];

  self.eventsPurchasedArchived = [NSMutableArray array];
  self.eventsPurchasedUpcoming = [NSMutableArray array];

  self.lastUpcomingCallPage = [NSNumber numberWithInt:0];
  self.lastArchiveCallPage = [NSNumber numberWithInt:0];

  self.eventsPurchased = [NSMutableArray array];

  [self upcomingButtonTapped:self.upcomingButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTextAndFont {
  
  [self.upcomingButton setTitle:NSLocalizedString(kUpcomingButtonTitle, @"").uppercaseString
                       forState:UIControlStateNormal];
  [self.archiveButton setTitle:NSLocalizedString(kArchiveButtonTitle, @"").uppercaseString
                      forState:UIControlStateNormal];
  [self.needToDiscussLabel setText:NSLocalizedString(kNeedToDiscussLabel, @"")];
  [self.contactYourConciergeButton setTitle:NSLocalizedString(kContactYourConciergeButtonTitle, @"").capitalizedString
                                   forState:UIControlStateNormal];

  [self.noPurchaseHistoryLabel setText:NSLocalizedString(kNoPurchaseHistoryLabelText, @"")];
  [self.noPurchaseHistoryMessageLabel setText:NSLocalizedString(kNoPurchaseHistoryMessageLabelText, @"")];

}
- (void)showPurchasedEventDetailsView{

  CGAffineTransform (^ generateTransform)(CGFloat scale)  = ^(CGFloat scale) {
    return CGAffineTransformMakeScale(scale, scale);
  };

  self.purchasedEventDetailsView.bgImage.image = nil;

  self.purchasedEventDetailsView.transform = generateTransform(0.3);

  [UIView animateWithDuration:kAnimationTime/2
                   animations:^{
                     self.purchasedEventDetailsView.transform = generateTransform(1.05);
                   }
                   completion:^(BOOL finished) {
                     [self.purchasedEventDetailsView.bgImage setImage:[UIImage imageNamed:@"7_01_Main_BG"]];
                     [UIView animateWithDuration:kAnimationTime/4
                                      animations:^{
                                        self.purchasedEventDetailsView.transform = generateTransform(0.95);
                                      }
                                      completion:^(BOOL finished) {
                                        [UIView animateWithDuration:kAnimationTime/4
                                                         animations:^{
                                                           self.purchasedEventDetailsView.transform = generateTransform(1.0);
                                                         }
                                                         completion:nil];
                                      }];
                   }];


  [self.view addSubview:self.purchasedEventDetailsView];
  
}

- (IBAction)upcomingButtonTapped:(id)sender {
  self.reservationType = CSReservationTypeUpcoming;
  if (self.lastUpcomingCallPage.intValue <= 1) {
    [self makeReservationsCall];
  }
}

- (IBAction)archiveButtonTapped:(id)sender {
  self.reservationType = CSReservationTypeArchive;
  if (self.lastArchiveCallPage.intValue <= 1) {
    [self makeReservationsCall];
  }
}

- (IBAction)contactYourConciergeTapped:(id)sender {
  [self performSegueWithIdentifier:kContactYourConciergeSegue sender:self];
}

- (void)setReservationType:(CSReservationType)reservationType{
  switch (reservationType) {
    case CSReservationTypeArchive:
      _reservationType = CSReservationTypeArchive;
      [self setActiveStateOnButton:self.archiveButton];
      break;
    case CSReservationTypeUpcoming:
      _reservationType = CSReservationTypeUpcoming;
      [self setActiveStateOnButton:self.upcomingButton];
      break;
  }
}

- (CSReservationType)reservationType{
  return _reservationType;
}

# pragma mark - UITableView Delegate and Data Source methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  static NSString * cellIdentifier = @"PurchaseHistoryCell";
  PurchaseHistoryCell *cell = (PurchaseHistoryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [PurchaseHistoryCell purchaseHistoryCell];
  }
  [cell setDelegate:self];
  Event * event = [[self eventsPurchasedDataSourceForSection:indexPath.section] objectAtIndex:indexPath.row];
  [cell setEvent:event];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  return kPurchaseHistoryCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
  NSString * sectionTitle = nil;
  if (self.reservationType == CSReservationTypeArchive) {
    if(section == kYearSection){
      sectionTitle = NSLocalizedString(@"PurchaseHistory_WithinLastYear", @"");
    } else if(section == kMonthSection){
      sectionTitle = NSLocalizedString(@"PurchaseHistory_WithinLastThirtyDays", @"");
    } else{
      sectionTitle = NSLocalizedString(@"PurchaseHistory_WithinLastWeek", @"");
    }
  }
  
  CGRect frame = CGRectMake(0.0, 0.0, kFullScreenWidth, kSectionHeaderHeight);
  UIView * headerView = [[UIView alloc] initWithFrame:frame];
  [headerView setBackgroundColor:[UIColor clearColor]];
  frame.origin.x = 20.0;
  frame.size.height = 20.0;
  UILabel * headerTitleLabel = [[UILabel alloc] initWithFrame:frame];
  [headerTitleLabel setBackgroundColor:[UIColor clearColor]];
  [headerTitleLabel setText:sectionTitle];
  [headerTitleLabel setTextColor:kClubscorePurpleBlack];
  [headerTitleLabel setFont:[UIFont avenirBlackWithSize:13.0]];
  [headerView addSubview:headerTitleLabel];
  
  return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  NSInteger sections = 0;
  if (self.reservationType == CSReservationTypeArchive) {
    sections += self.eventsPurchasedArchivedWeek.count>0?1:0;
    sections += self.eventsPurchasedArchivedMonth.count>0?1:0;
    sections += self.eventsPurchasedArchivedYear.count>0?1:0;
  } else{
    sections = 1;
  }

  return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  int numberOfRows = [self eventsPurchasedDataSourceForSection:section].count;
  [self showNoEventsPurchasedView:(numberOfRows<=0)];
  return numberOfRows;
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
  // load more nodes when table view scrolls to bottom
  CGPoint offset = aScrollView.contentOffset;
  CGRect bounds = aScrollView.bounds;
  CGSize size = aScrollView.contentSize;
  UIEdgeInsets inset = aScrollView.contentInset;
  float y = offset.y + bounds.size.height - inset.bottom;
  float h = size.height;
  if (y > (h - 1)) {
    if([self.paginator hasNextPage]){
      DLog(@"Next Page");
      if(!self.isPaginatorLoading){
        self.isPaginatorLoading = YES;
        [self.paginator loadNextPage];
      }
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  self.purchasedEventDetailsView = [PurchasedEventDetails purchasedEventDetails];
  [self.purchasedEventDetailsView setDelegate:self];
  
  Event * currentEvent = [[self eventsPurchasedDataSourceForSection:indexPath.section] objectAtIndex:indexPath.row];
  (currentEvent!=nil)?[self.purchasedEventDetailsView setEvent:currentEvent]:nil;
  
  CGRect frame = self.purchasedEventDetailsView.frame;
  frame.origin.y = 0.0;
  frame.size.height = self.view.frame.size.height;
  [self.purchasedEventDetailsView setFrame:frame];
  [self showPurchasedEventDetailsView];
}

- (void)setActiveStateOnButton:(UIButton *)button{
  [button setBackgroundImage:[UIImage imageNamed:@"7_05_Archive-Button_Active"] forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageNamed:@"7_05_Archive-Button_Normal"] forState:UIControlStateSelected];
  button = (button == self.upcomingButton)?self.archiveButton:self.upcomingButton;
  [button setBackgroundImage:[UIImage imageNamed:@"7_05_Archive-Button_Normal"] forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageNamed:@"7_05_Archive-Button_Active"] forState:UIControlStateSelected];
}


- (void)didTapCloseButton{
  self.purchasedEventDetailsView.transform = CGAffineTransformMakeScale(1.05, 1.05);
  [UIView animateWithDuration:kAnimationTime/2
                   animations:^{
                     self.purchasedEventDetailsView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                   }
                   completion:^(BOOL finished) {
                     [self.purchasedEventDetailsView removeFromSuperview];
                   }];
}

- (void) makeReservationsCall{

  // TODO: This methods needs some refactoring 
  
  // Create weak reference to self to use within the paginators completion block
  __weak typeof(self) weakSelf = self;
  weakSelf.objects = [NSMutableArray array];
  
  [self.eventsPurchasedTableView setContentOffset:CGPointZero animated:NO];
  if(self.reservationType == CSReservationTypeUpcoming){
    [self.needToDiscussLabel setHidden:NO];
    [self.contactYourConciergeButton setHidden:NO];
    [self.eventsPurchasedTableView setFrame:CGRectMake(0.0, 15.0, 320.0, 210.0)];
  }else{
    if(IS_4INCH_SCREEN){
      [self.eventsPurchasedTableView setFrame:CGRectMake(0.0,15.0, 320.0, 415.0)];
    }else{
      [self.eventsPurchasedTableView setFrame:CGRectMake(0.0,15.0, 320.0, 328.0)];
    }
    [self.needToDiscussLabel setHidden:YES];
    [self.contactYourConciergeButton setHidden:YES];
  }
  
  if(((self.reservationType == CSReservationTypeUpcoming) && (self.eventsPurchasedUpcoming.count > 0)) || ((self.reservationType == CSReservationTypeArchive) && (self.eventsPurchasedArchived.count > 0))){
    //Events are already loaded, no need to load them again
    [self updateDatasource];
    return;
  }
  
  // TODO: Remove this later
  self.paginator = nil;
  
  // Setup paginator
  if (!self.paginator) {
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    NSString *requestString;
    //Give the URL path
    if(self.reservationType == CSReservationTypeUpcoming){
       requestString = [NSString stringWithFormat:kUrlStringForUpcoming];
    }else if(self.reservationType == CSReservationTypeArchive){
       requestString = [NSString stringWithFormat:kUrlStringForArchive];
    } else{
      requestString = @"";
    }
   
    self.paginator = [objectManager paginatorWithPathPattern:requestString];
    self.paginator.perPage = 10; // this will request /posts?page=N&per_page=20
    [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];

    //Set completion block for this paginator
    [self.paginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
      weakSelf.isPaginatorLoading = NO;
      [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
      if (page == 1) {
        [weakSelf.objects removeAllObjects];
        if(weakSelf.reservationType == CSReservationTypeUpcoming){
           weakSelf.eventsPurchasedUpcoming = [NSMutableArray array];
        } else if (weakSelf.reservationType == CSReservationTypeArchive){
          weakSelf.eventsPurchasedArchived = [NSMutableArray array];
        }
      }
      [weakSelf.objects addObjectsFromArray:objects];
      [weakSelf.eventsPurchasedTableView setHidden:NO];

      if (weakSelf.reservationType == CSReservationTypeUpcoming) {
        [weakSelf.eventsPurchasedUpcoming addObjectsFromArray:weakSelf.objects];
      } else if (weakSelf.reservationType == CSReservationTypeArchive){
        if(IS_4INCH_SCREEN){
          [weakSelf.eventsPurchasedTableView setFrame:CGRectMake(0.0,15.0, 320.0, 415.0)];
        }else{
          [weakSelf.eventsPurchasedTableView setFrame:CGRectMake(0.0,15.0, 320.0, 328.0)];
        }
        [weakSelf.eventsPurchasedArchived addObjectsFromArray:weakSelf.objects];
        const int secondsperday = 86400;
        weakSelf.eventsPurchasedArchivedYear = [NSMutableArray array];
        weakSelf.eventsPurchasedArchivedMonth = [NSMutableArray array];
        weakSelf.eventsPurchasedArchivedWeek = [NSMutableArray array];

        for (Event *archivedEvent in weakSelf.eventsPurchasedArchived) {
          if ([archivedEvent.startDate compare:[NSDate dateWithTimeIntervalSinceNow:(-1*secondsperday * 30)]] == NSOrderedAscending){
              // If the event date is earlier than 30Days
            [weakSelf.eventsPurchasedArchivedYear addObject:archivedEvent];
          } else if ([archivedEvent.startDate compare:[NSDate dateWithTimeIntervalSinceNow:(-1*secondsperday * 7)]] == NSOrderedAscending){
              // If the event date is earlier than last week
            [weakSelf.eventsPurchasedArchivedMonth addObject:archivedEvent];
          } else {
              // If event date is within last week
            [weakSelf.eventsPurchasedArchivedWeek addObject:archivedEvent];
          }
        }
      }
      
      [weakSelf updateDatasource];
  } failure:^(RKPaginator *paginator, NSError *error) {
     [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
    if(weakSelf.reservationType == CSReservationTypeUpcoming){
      [weakSelf showNoEventsPurchasedView:YES];
    }else{
      [UIAlertView showAlertForError:error];
    }
      
      weakSelf.paginator = nil;
  }];
  }
  DLog(@"Loaded Objects are %@",weakSelf.objects);
  [self.paginator loadPage:1];

}

- (void)updateDatasource{
  if (self.reservationType == CSReservationTypeUpcoming) {
    self.eventsPurchased = [NSMutableArray arrayWithArray:self.eventsPurchasedUpcoming];
  } else if(self.reservationType == CSReservationTypeArchive){
    self.eventsPurchased = [NSMutableArray arrayWithArray:self.eventsPurchasedArchived];
  }
  [self.eventsPurchasedTableView reloadData];
}

- (void)deleteRowsAtIndexPaths: (NSMutableArray*)indexPaths {
  [self.eventsPurchasedTableView beginUpdates];
  [self.eventsPurchasedTableView deleteRowsAtIndexPaths:indexPaths
                                       withRowAnimation:UITableViewRowAnimationLeft];
  [self.eventsPurchasedTableView endUpdates];
}

-(void)showNoEventsPurchasedView:(BOOL)hide{
  [self.noEventsPurchasedView setHidden:!hide];
  if (self.reservationType == CSReservationTypeUpcoming) {
    [self.needToDiscussLabel setHidden:hide];
    [self.contactYourConciergeButton setHidden:hide];
    [self.eventsPurchasedTableView setHidden:hide];
  }
}

#pragma mark - PurchaseHistoryCell delegate methods

- (void)removeButtonWillShowForCell:(PurchaseHistoryCell *)purchaseHistoryCell{

  NSIndexPath *indexPath = [self.eventsPurchasedTableView indexPathForCell:purchaseHistoryCell];
  if(![indexPath isEqual:self.currentIndexPath] )
    {
    self.previousIndexPath = self.currentIndexPath;
    self.currentIndexPath  = indexPath;
    }
  if(self.previousIndexPath)
    {
    PurchaseHistoryCell *cell = (PurchaseHistoryCell*)[self.eventsPurchasedTableView cellForRowAtIndexPath:self.previousIndexPath];
    [cell slideRight];
    }
}

-(void)restoreButtonDidHideForCell:(PurchaseHistoryCell *)trashCell
{
  NSIndexPath * indexpath = [self.eventsPurchasedTableView indexPathForCell:trashCell];
  if ([indexpath isEqual:self.currentIndexPath]) {
    self.currentIndexPath = nil;
  }
}


- (void)didTapRemoveButton:(PurchaseHistoryCell *)thePurchaseHistoryCell{
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  [Event hideReservationWithId:thePurchaseHistoryCell.event.reservationId withCompletion:^(BOOL success, NSArray *result, NSError *error) {
  [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (success) {
      NSIndexPath * indexPath = [self.eventsPurchasedTableView indexPathForCell:thePurchaseHistoryCell];
      [[self eventsPurchasedDataSourceForSection:indexPath.section] removeObjectAtIndex:indexPath.row];
      [self deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]];
      (self.eventsPurchased.count <= 0)?[self showNoEventsPurchasedView:YES]:nil;
    } else {
        //call failed
    }
  }];
}

- (NSMutableArray*)eventsPurchasedDataSourceForSection:(NSInteger)section{
  NSMutableArray * dataSource;
  
  if(self.reservationType == CSReservationTypeUpcoming){
    dataSource = self.eventsPurchased;
  } else{
    switch (section) {
      case kYearSection:
        dataSource = self.eventsPurchasedArchivedYear;
        break;
      case kMonthSection:
        dataSource = self.eventsPurchasedArchivedMonth;
        break;
      case kWeekSection:
        dataSource = self.eventsPurchasedArchivedWeek;
        break;
    }
  }
  
  return dataSource;
}

@end
