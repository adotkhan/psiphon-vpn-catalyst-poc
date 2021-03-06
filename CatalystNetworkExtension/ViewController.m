//
//  ViewController.m
//  CatalystNetworkExtension
//
//  Created by Amir Khan on 2020-12-16.
//

#import "ViewController.h"
#import <NetworkExtension/NEVPNManager.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *toggle;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (strong, nonatomic, nullable) NETunnelProviderManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.status setText:@""];

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {

        if (error != nil) {
            NSLog(@"ERROR: %@", error);
            return;
        }

        if (managers.count == 1) {
            self.manager = managers[0];
            [self observeTunnelStatus];

        } else if (managers.count > 1) {
            [NSException raise:@"Invalid" format:@"More than 1 config found"];
        }

    }];

}

- (void)createAndSaveNewVPNConfig {

    NETunnelProviderProtocol *provider = [[NETunnelProviderProtocol alloc] init];
//    provider.providerBundleIdentifier = @"ca.psiphon.CatalystNetworkExtension.PacketTunnel";
    provider.providerBundleIdentifier = @"ca.psiphon.CatalystNetworkExtension.MacNE";
    provider.serverAddress = @"localhost";

    self.manager = [[NETunnelProviderManager alloc] init];
    self.manager.protocolConfiguration = provider;
    [self.manager setEnabled:TRUE];

    [self.manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"ERROR1: %@", error);
            return;
        }

        [self.manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"ERROR2: %@", error);
                return;
            }

            NETunnelProviderSession *connection = (NETunnelProviderSession*)self.manager.connection;

            [self observeTunnelStatus];

        }];

    }];

}


- (void)updateConnectionStatus {
    NSString *string = nil;
    switch ((NEVPNStatus)self.manager.connection.status) {
        case NEVPNStatusInvalid:
            string = @"invalid";
            break;
        case NEVPNStatusDisconnected:
            string = @"disconnected";
            break;
        case NEVPNStatusConnecting:
            string = @"connecting";
            break;
        case NEVPNStatusConnected:
            string = @"connected";
            break;
        case NEVPNStatusReasserting:
            string = @"reasserting";
            break;
        case NEVPNStatusDisconnecting:
            string = @"disconnecting";
            break;
        default:
            string = [NSString stringWithFormat:@"invalid status (%ld)",
                      (long)self.manager.connection.status];
    }
    [self.status setText:string];
}

- (void)observeTunnelStatus {

    [self updateConnectionStatus];

    [[NSNotificationCenter defaultCenter]
     addObserverForName:NEVPNStatusDidChangeNotification
     object:self.manager.connection
     queue:NSOperationQueue.mainQueue
     usingBlock:^(NSNotification *_Nonnull note) {
        [self updateConnectionStatus];
    }];
}

// The following error printed in the logs is due to UIKit and can be ignored:
// invalid mode 'kCFRunLoopCommonModes' provided to CFRunLoopRunSpecific - break on _CFRunLoopError_RunCalledWithInvalidMode to debug. This message will only appear once per execution.

- (IBAction)toggle:(UISwitch *)sender {

    NETunnelProviderSession *connection = (NETunnelProviderSession*)self.manager.connection;

    if ([sender isOn]) {

        NSError *err = nil;

        NSDictionary<NSString *, NSString *> *options = @{@"hello": @"hi"};
        BOOL success = [connection startTunnelWithOptions:options andReturnError:&err];

        NSLog(@"Tunnel start success: %hhd", success);

        if (err != nil) {
            NSLog(@"ERROR3: %@", err);
            return;
        }

    } else {

        [connection stopTunnel];

    }


}

- (IBAction)onUninstallVPNConfig:(id)sender {
    [self.manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"ERROR Uninstall vpn config: %@", error);
            return;
        }
    }];
}

- (IBAction)onInstallVPNConfig:(id)sender {
    [self createAndSaveNewVPNConfig];
}


@end
