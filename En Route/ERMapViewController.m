//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"


@implementation ERMapViewController


- (void)loadView {
    self.view = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (MKMapView *)mapView {
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)]; //targets self bc clear button
    self.navigationItem.leftBarButtonItem = button; //clear button
    
    self.navigationController.toolbarHidden = NO;
    self.title = @"En Route";
}

- (void)clearButtonPressed {
    
}

@end
