//
//  DataBaseQuery.h
//  ChapterStory
//
//  Created by fejleszto on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"



@interface DataBaseQuery : NSObject {
    
}

//retuns 
+(NSMutableArray*)textQueryWithFile:(NSString*)fileName AndQsql:(NSString*)qsql;
+ (void)executeQsqlArray:(NSArray*)qsqlArray inFile:(NSString*)fileName;
@end
