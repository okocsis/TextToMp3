 //
//  DataBaseQuery.m
//  ChapterStory
//
//  Created by fejleszto on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DataBaseQuery.h"


@implementation DataBaseQuery



+(sqlite3*)openDatabase:(NSString*)fileName
{
    
    sqlite3 *db;
    if ( sqlite3_open([fileName UTF8String], &db) != SQLITE_OK ) 
    {
        sqlite3_close(db);
        NSAssert(0,@"Database failed to open");
        return NULL;
    }
    return db;
}

+ (void)executeQsqlArray:(NSArray*)qsqlArray inFile:(NSString*)fileName 
{
    sqlite3* db = [DataBaseQuery openDatabase:fileName];

    sqlite3_stmt *statement;
        
    if (db)
    {
        for (NSString* qsql in qsqlArray)
        {
           // NSLog(qsql);
            sqlite3_prepare_v2(db, [qsql UTF8String], -1, &statement, nil);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }		
}

+ (NSMutableArray*) textQueryWithFile:(NSString*)fileName AndQsql:(NSString*)qsql
{
    NSMutableArray *queryResult = NULL;

    sqlite3* db = [DataBaseQuery openDatabase:fileName];
    
    if(db)
    {
        queryResult = [NSMutableArray array]; 
        
        // Setup the SQL Statement
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(db, [qsql UTF8String], -1, &statement, nil)==SQLITE_OK)
        {
            int columns = sqlite3_column_count(statement);
            while (sqlite3_step(statement) == SQLITE_ROW)
            {   
                NSMutableArray *recordArray = [[NSMutableArray alloc] init];
                
                const char *field;
                
                for(int i = 0; i < columns; i++)
                {
                    if((field = (char*)sqlite3_column_text(statement, i)) ==   nil){
                        field = "";
                    }
                    NSString  *fieldString = [NSString  stringWithUTF8String:field];
                                  
                    [recordArray addObject: fieldString];
                }
                
                [queryResult addObject:recordArray];
                //arc code
//                [recordArray release];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }
    return queryResult;
}

@end
