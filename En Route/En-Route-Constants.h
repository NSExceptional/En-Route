//
//  En-Route-Constants.h
//  En Route
//
//  Created by Tanner on 2/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString * const kCurrentLocationText;


NS_INLINE CGRect CGRectInsetLeft(CGRect r, CGFloat dx, CGFloat dy) {
    r.origin.x += dx;
    r.size.width -= dx;
    r.origin.y += dy;
    r.size.height -= dy;
    
    if (r.size.width < 0 || r.size.height < 0) {
        return CGRectNull;
    }
    
    return r;
}
