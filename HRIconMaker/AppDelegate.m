//
//  AppDelegate.m
//  HRIconMaker
//
//  Created by ZhangHeng on 16/1/13.
//  Copyright © 2016年 ZhangHeng. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
    NSString *selectPath;
    NSString *iconPath;
    IBOutlet    NSTextField     *remindLabel;
    IBOutlet    NSTextField     *remindIcon;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(IBAction)selectIconFile:(id)sender{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"png", @"PNG", nil];
    [openDlg setAllowedFileTypes:fileTypes];
    if ([openDlg runModal] == NSModalResponseOK){
        NSURL  *icon = [[openDlg URLs] firstObject];
        iconPath = icon.path;
        remindIcon.stringValue = iconPath;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *saveDoubleDir = [[iconPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"icon"];
    
    BOOL isDir;
    if(![fm fileExistsAtPath:saveDoubleDir isDirectory:&isDir] || !isDir){
        [fm createDirectoryAtPath:saveDoubleDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

}

-(IBAction)startMakeIcon:(id)sender{
    if(!iconPath){
        remindIcon.stringValue = @"请先选择原图片";
        return;
    }
    NSMutableArray *sizes = @[@(29),@(58),@(87),@(80),@(120),@(180),@(57),@(114)].mutableCopy;
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:iconPath];
    [self saveIconsInqueue:sizes withImage:image];
}

-(void)saveIconsInqueue:(NSMutableArray *)sizes withImage:(NSImage *)image{
    remindIcon.stringValue = @"处理中...";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSNumber *size = sizes[0];
        NSImage *smallImage = [self imageByScalingProportionallyToSize:CGSizeMake(size.intValue, size.intValue) withOrigalImage:image];
        
        NSBitmapImageRep *bits = [self bitmapImageRepresentationWithImage:smallImage]; // get a rep from your image, or grab from a view
        NSData *data = [bits representationUsingType: NSPNGFileType properties: nil];
        [data writeToFile:[self getFinalIconSavePath:iconPath withSize:size.intValue] atomically:YES];
        [sizes removeObjectAtIndex:0];
        if(sizes.count == 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"completed");
                remindIcon.stringValue = @"完成处理！";
            });
        }else{
            [self saveIconsInqueue:sizes withImage:image];
        }
    });
}

-(IBAction)selectSourcePath:(id)sender{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    if ( [openDlg runModal] == NSModalResponseOK){
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* files = [openDlg URLs];
        
        // Loop through all the files and process them.
        for( int i = 0; i < [files count]; i++ ){
            NSURL *fileURL = [files objectAtIndex:i];
            selectPath = fileURL.path;
            remindLabel.stringValue = selectPath;
        }
    }
}

-(IBAction)selectOutputPath:(id)sender{
    if(!selectPath){
        remindLabel.stringValue = @"请先选择路径";
        return;
    }
    
    NSMutableArray *plusImages = [NSMutableArray new];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *subFiles = [fm contentsOfDirectoryAtPath:selectPath error:nil];
    NSString *saveDoubleDir = [selectPath stringByAppendingPathComponent:@"2X"];
    
    BOOL isDir;
    if(![fm fileExistsAtPath:saveDoubleDir isDirectory:&isDir] || !isDir){
        [fm createDirectoryAtPath:saveDoubleDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    for(NSString *path in subFiles){
        if([[path stringByDeletingPathExtension] hasSuffix:@"@3x"]){
            [plusImages addObject:[selectPath stringByAppendingPathComponent:path]];
        }
    }
    [self outputImagesForOtherDevice:plusImages];
}

-(void)outputImagesForOtherDevice:(NSMutableArray *)paths{
    remindLabel.stringValue = @"处理中...";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *path = paths[0];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
        NSImage *smallImage = [self imageWithBigImage:image];
    
        NSBitmapImageRep *bits = [self bitmapImageRepresentationWithImage:smallImage]; // get a rep from your image, or grab from a view
        NSData *data = [bits representationUsingType: NSPNGFileType properties: nil];
        [data writeToFile:[self getFinalSavePath:path] atomically:YES];
        [paths removeObjectAtIndex:0];
        if(paths.count == 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"completed");
                remindLabel.stringValue = @"完成处理！";
            });
        }else{
            [self outputImagesForOtherDevice:paths];
        }
    });
}

-(NSString *)getFinalIconSavePath:(NSString *)bigIconPath withSize:(int)sizeValue{
    NSString *dir = [bigIconPath stringByDeletingLastPathComponent];
    return [[dir stringByAppendingPathComponent:@"icon"] stringByAppendingPathComponent:[NSString stringWithFormat:@"icon%d.png",sizeValue]];
}

-(NSString *)getFinalSavePath:(NSString *)origalPath{
    NSString *fileName = [origalPath lastPathComponent];
    NSString *dirPath = [origalPath stringByDeletingLastPathComponent];
    
    return [[dirPath stringByAppendingPathComponent:@"2X"] stringByAppendingPathComponent:[fileName stringByReplacingOccurrencesOfString:@"@3x" withString:@"@2x"]];
}

- (NSBitmapImageRep *)bitmapImageRepresentationWithImage:(NSImage *)image{
    int width = [image size].width;
    int height = [image size].height;
    
    if(width < 1 || height < 1)
        return nil;
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes: NULL
                             pixelsWide: width
                             pixelsHigh: height
                             bitsPerSample: 8
                             samplesPerPixel: 4
                             hasAlpha: YES
                             isPlanar: NO
                             colorSpaceName: NSDeviceRGBColorSpace
                             bytesPerRow: width * 4
                             bitsPerPixel: 32];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: ctx];
    [image drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1];
    [ctx flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    return rep;
}

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize withOrigalImage:(NSImage *)image{
    NSImage* sourceImage = image;
    NSImage* newImage = nil;
    
    if ([sourceImage isValid]){
        NSSize imageSize = [sourceImage size];
        float width  = imageSize.width;
        float height = imageSize.height;
        
        float targetWidth  = targetSize.width;
        float targetHeight = targetSize.height;
        
        float scaleFactor  = 0.0;
        float scaledWidth  = targetWidth;
        float scaledHeight = targetHeight;
        
        NSPoint thumbnailPoint = NSZeroPoint;
        
        if ( NSEqualSizes( imageSize, targetSize ) == NO ){
            float widthFactor  = targetWidth / width;
            float heightFactor = targetHeight / height;
            
            if ( widthFactor < heightFactor )
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;
            
            scaledWidth  = width  * scaleFactor;
            scaledHeight = height * scaleFactor;
            
            if ( widthFactor < heightFactor )
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            
            else if ( widthFactor > heightFactor )
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
        newImage = [[NSImage alloc] initWithSize:targetSize];
        [newImage lockFocus];
        NSRect thumbnailRect;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        [sourceImage drawInRect: thumbnailRect
                       fromRect: NSZeroRect
                      operation: NSCompositeSourceOver
                       fraction: 1.0];
        [newImage unlockFocus];
    }
    return newImage;
}

- (NSImage *)imageWithBigImage:(NSImage*)bigImage{
    NSImage *sourceImage = bigImage;
    NSImageRep * imageRep = bigImage.representations.firstObject;
    
    CGSize newSize = CGSizeMake(imageRep.pixelsWide*2/3, imageRep.pixelsHigh*2/3);
    
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        return [self imageByScalingProportionallyToSize:newSize withOrigalImage:bigImage];
    }
    return nil;
}

@end
