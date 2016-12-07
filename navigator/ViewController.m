//
//  ViewController.m
//  navigator
//
//  Created by Pascal CAMARA on 23/11/2016.
//  Copyright © 2016 Pascal CAMARA. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *searchText;
@property (weak, nonatomic) IBOutlet UITextView *resultText;

-(void)makeSession:(NSString * )url with:(UITextView * )itemTextView;
@property (weak, nonatomic) IBOutlet UIImageView *imageDataView;

@property NSFileManager * m;
@property NSString * pathUrlCache;


@end

@implementation ViewController
- (IBAction)doSearch:(id)sender {
    // je récupère le text en string
    NSString * url = self.searchText.text;
    
    if (![url hasPrefix:@"http://"] && ! [url hasPrefix:@"https://"]) {
        url = [NSString stringWithFormat:@"http://%@",url];
    }
    
    NSString * urlHash = [url MD5];
    //NSLog(@"url %@", urlHash);
    
    NSLog(@"debug : %@" , url);
    self.resultText.text = @"test";
    
     self.pathUrlCache = [NSString stringWithFormat:@"%@", urlHash];
    //NSLog(@"file debug : %@", pathUrlCache);
    //NSLog(@"File exist ? : %d\n", [m fileExistsAtPath:pathUrlCache] );
    // demande si file exist
    if ([self.m fileExistsAtPath:self.pathUrlCache]) {
        // verrify cache http://stackoverflow.com/questions/13497500/retrieve-file-creation-or-modification-date
        NSURL * fileUrl = [NSURL fileURLWithPath:self.pathUrlCache];
        NSDate * fileDate = nil;
        NSError *  error = nil;
        [fileUrl getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:&error];
        if (!error) {
            //NSLog(@"file date %@", fileDate);
            //NSString * dateTestString = @"2016-11-20";
            //NSDateFormatter *f = [[NSDateFormatter alloc] init];
            //[f setDateFormat:@"yyyy-MM-dd"];
            //NSDate *dateTEST = [f dateFromString:dateTestString];
            
            NSDate * now = [NSDate new];
            NSLog(@"date now : %@", now);
            // compte the date to retrieve day differences http://stackoverflow.com/questions/4575689/objective-c-calculating-the-number-of-days-between-two-dates
            NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                fromDate:fileDate
                                                                  toDate:now
                                                                 options:0];
            int fileDays = [components day];
            //NSLog(@"day differences : %d", fileDays );
            if (fileDays > 7)  {
                // delete cache
                [self.m removeItemAtPath:self.pathUrlCache error:&error];
                [self makeSession:url with:self.resultText];
            }
        }
        
        // get data file
        self.resultText.text = [[NSString alloc] initWithContentsOfFile:self.pathUrlCache];
        
    } else {
        // make session
        NSLog(@"file makesession %@", urlHash);
         [self makeSession:url with:self.resultText];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // recupération file manager
    self.m = [NSFileManager defaultManager];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)makeSession:(NSString *)url with:(UITextView *)itemTextView {
    //NSLog(@"makeSession : %@", url);
    //NSLog(@"makeSession : %@", itemTextView);
    
    //je fait ma requette http avec en param le text (string)
    NSURL * toLoad = [NSURL URLWithString:url];
    
    
    // je démare la session
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:toLoad completionHandler:
                                  ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                      
        if (error == nil) {
            
                                          
            NSLog(@"iiii data %@", data);
            NSLog(@"iiii response %@", response);
            
           
            dispatch_async(dispatch_get_main_queue(), ^{
                // On récupère le content type de la response
                NSString * contentType = [(NSHTTPURLResponse*)response allHeaderFields][@"Content-Type"];
                
                // on regarde s'il s'agit d'une image
                
                NSLog(@"iiii content type : %@", contentType);
                // http://stackoverflow.com/questions/2753956/how-do-i-check-if-a-string-contains-another-string-in-objective-c
               if ([contentType rangeOfString:@"image/"].location != NSNotFound) {
                   // data to image
                   UIImage * image = [UIImage imageWithData:data];
                   
                   
                   // afficher image
                   self.imageDataView.hidden = NO;
                   self.resultText.hidden = YES;
                   self.imageDataView.image = image;
                   
                   /*UIImage *image = [[UIImage alloc] init];
                   UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                   UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                   [iv setImage:image];
                   [v addSubview:iv];*/
                   
                   
                   
               } else {
                   // afficher text
                   NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                   
                   self.imageDataView.hidden = YES;
                   self.resultText.hidden = NO;

                   self.resultText.text = stringData;
                   
                   // write save in cache
                   if ([self.m fileExistsAtPath:self.pathUrlCache]) {
                       [stringData writeToFile:self.pathUrlCache atomically:YES];
                   } else {
                       [stringData writeToFile:self.pathUrlCache atomically:YES];
                   }

               }
                
                
                
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultText.text = [NSString stringWithFormat: @"Error %@", error];
            });
        }
                                      
    }];
    
    [task resume];

}


@end
