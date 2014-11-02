//
//  NSData+gzip.h
//  QLFits3
//
//  Created by Cédric Foellmi on 31/10/14.
//  Copyright (c) 2014 onekiloparsec. All rights reserved.
//

//  http://cocoadev.com/w190/index.php?title=NSDataCategory&action=edit

#import <Foundation/Foundation.h>

@interface NSData (gzip)

- (NSData *)gunzippedData;
- (NSData *)gzippedData;

@end
