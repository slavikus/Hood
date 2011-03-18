#import <UIKit/UIKit.h>

@interface BluetoothDevice : NSObject
{
    NSString * _name;
    NSString * _address;
    struct BTDeviceImpl * _device;
}

- (char)isAccessory;
- (char)available;
- (char)supportsBatteryLevel;
- (char)isServiceSupported:(unsigned int)fp8;
- (int)batteryLevel;
- (int)compare:(id)fp8;
- (void)disconnect;
- (void)unpair;
- (void)setPIN:(id)fp8;
- (void)connect;
- (char)paired;
- (char)connected;
- (int)type;
- (id)address;
- (id)description;
- (id)name;
- (void)setDevice:(struct BTDeviceImpl *)fp8;
- (struct BTDeviceImpl *)device;
- (void)dealloc;
- (void)_setDirty;
- (id)initWithDevice:(struct BTDeviceImpl *)fp8 address:(id)fp12;
@end

@interface BluetoothAudioJack : NSObject
{
    struct BTAudioJackImpl * _jack;
    NSMutableArray * _devices;
    NSMutableArray * _outOfCallDevices;
    char _monitoring;
}

- (char)available:(id)fp8;
- (id)availableDevicesForOutOfCallRouting;
- (id)availableDevices;
- (void)removeDevice:(struct BTDeviceImpl *)fp8;
- (void)addDevice:(struct BTDeviceImpl *)fp8;
- (struct BTAudioJackImpl *)jack;
- (char)connected;
- (void)disconnect;
- (void)connect:(id)fp8;
- (void)stopMonitoring;
- (void)startMonitoring;
- (void)_loadDevices;
- (void)dealloc;
- (id)initWithAudioJack:(struct BTAudioJackImpl *)fp8;
@end

@interface BluetoothManager : NSObject
{
    struct BTLocalDeviceImpl * _localDevice;
    struct BTSessionImpl * _session;
    char _audioConnected;
    char _scanningEnabled;
    char _pairingEnabled;
    int _powerState;
    int _connectedState;
    struct BTDiscoveryAgentImpl * _discoveryAgent;
    struct BTPairingAgentImpl * _pairingAgent;
    struct BTAccessoryManagerImpl * _accessoryManager;
    NSMutableDictionary * _bluetoothDeviceDict;
    NSMutableDictionary * _btDeviceDict;
    BluetoothAudioJack * _audioJack;
}

- (void)enableTestMode;
- (id)audioJack;
- (void)setConnectable:(char)fp8;
- (char)connectable;
- (void)setDiscoverable:(char)fp8;
- (char)isDiscoverable;
- (unsigned int)getAuthorizatedServicesForDevice:(id)fp8;
- (void)setServiceAuthorization:(unsigned int)fp8 authorized:(char)fp12 forDevice:(id)fp16;
- (void)unpairDevice:(id)fp8;
- (id)pairedDevices;
- (id)connectableDevices;
- (char)canBeConnected;
- (void)cancelPairing;
- (void)pairDevice:(id)fp8;
- (void)connectDevice:(id)fp8;
- (void)sendAllContactsToDevice:(id)fp8;
- (void)sendContact:(id)fp8 toDevice:(id)fp12;
- (void)setPincode:(id)fp8 forDevice:(id)fp12;
- (char)devicePairingEnabled;
- (void)setDevicePairingEnabled:(char)fp8;
- (char)deviceScanningEnabled;
- (void)setDeviceScanningEnabled:(char)fp8;
- (void)_removeDevice:(id)fp8;
- (id)addDeviceIfNeeded:(struct BTDeviceImpl *)fp8;
- (void)setAudioConnected:(char)fp8;
- (char)audioConnected;
- (void)setEnabled:(BOOL)fp8;
- (char)enabled;
- (void)setAirplaneMode:(BOOL)fp8;
- (char)setPowered:(BOOL)fp8;
- (void)_powerChanged:(BOOL)fp8;
- (char)powered;
- (void)_connectedStatusChanged;
- (char)connected;
- (id)init;
- (void)serverTerminated;
- (void)_setup;
- (void)_setupAccessoryManager;
- (void)_setupLocalDevice;
- (void)_setupSession;
- (void)postNotificationName:(id)fp8 object:(id)fp12 error:(id)fp16;
- (void)postNotificationName:(id)fp8 object:(id)fp12;
- (void)postNotification:(id)fp8;
- (void)_postNotification:(id)fp8;
- (void)_postNotificationWithArray:(id)fp8;
- (void)dealloc;
- (void)cleanup;
+ (void)initialize;
+ (id)sharedInstance;
@end


@interface BluetoothManager (BluetoothManagerPrivate)
- (struct BTAccessoryManagerImpl *)_accessoryManager;
@end

