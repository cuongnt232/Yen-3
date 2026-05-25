#import "CellProbeService.h"
#import "CoreTelephonyClientMinimal.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation CellProbeResult
@end

static NSString *CellProbeStringValue(id value) {
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return [[value description] copy];
}

static NSNumber *CellProbeNumberValue(id value) {
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        long long parsed = [(NSString *)value longLongValue];
        return @(parsed);
    }
    return nil;
}

static NSString *CellProbeNormalizedKey(NSString *key) {
    return [[key lowercaseString] stringByReplacingOccurrencesOfString:@"_" withString:@""];
}

static id CellProbeFindValue(NSDictionary *dictionary, NSArray<NSString *> *candidates) {
    if (dictionary.count == 0) {
        return nil;
    }

    NSMutableDictionary<NSString *, id> *normalized = [NSMutableDictionary dictionary];
    for (NSString *key in dictionary) {
        normalized[CellProbeNormalizedKey(key)] = dictionary[key];
    }

    for (NSString *candidate in candidates) {
        id value = normalized[CellProbeNormalizedKey(candidate)];
        if (value != nil && value != [NSNull null]) {
            return value;
        }
    }
    return nil;
}

static void CellProbeApplyLegacyDictionary(CellProbeResult *result, NSDictionary *dictionary) {
    if (dictionary.count == 0) {
        return;
    }

    if (result.pci == nil) {
        result.pci = CellProbeNumberValue(CellProbeFindValue(dictionary, @[
            @"pci", @"PhyCellId", @"PhysicalCellId", @"physicalCellId", @"physCellId"
        ]));
    }

    if (result.cid == nil) {
        result.cid = CellProbeNumberValue(CellProbeFindValue(dictionary, @[
            @"cid", @"cellId", @"CellId", @"cellid", @"ServingCellId"
        ]));
    }

    if (result.enbid == nil) {
        result.enbid = CellProbeNumberValue(CellProbeFindValue(dictionary, @[
            @"enbid", @"eNB", @"enb", @"baseId", @"BaseId", @"gNodeBId", @"nodeBId"
        ]));
    }

    if (result.eci == nil) {
        result.eci = CellProbeNumberValue(CellProbeFindValue(dictionary, @[
            @"eci", @"ECI", @"EutranCellId", @"eutranCellId", @"nrCellId", @"NRCellId"
        ]));
    }

    if (result.band.length == 0) {
        id bandValue = CellProbeFindValue(dictionary, @[
            @"band", @"Band", @"FreqBandIndicator", @"freqBandIndicator",
            @"activeBand", @"ActiveBand", @"nrBand", @"NRBand", @"lteBand", @"LTEBand"
        ]);
        result.band = CellProbeStringValue(bandValue);
    }
}

static void CellProbeApplyLegacyEntries(CellProbeResult *result, NSArray *legacyInfo) {
    for (id entry in legacyInfo) {
        if ([entry isKindOfClass:[NSDictionary class]]) {
            CellProbeApplyLegacyDictionary(result, (NSDictionary *)entry);
        }
    }
}

static void CellProbeFinalizeDerivedValues(CellProbeResult *result) {
    if (result.eci == nil && result.enbid != nil && result.cid != nil) {
        unsigned long long enb = result.enbid.unsignedLongLongValue;
        unsigned long long cid = result.cid.unsignedLongLongValue;

        if (cid <= 255) {
            result.eci = @(enb * 256ULL + (cid & 0xFFULL));
        } else if (cid > 255 && enb == 0) {
            result.eci = @(cid);
            result.enbid = @(cid / 256ULL);
            result.cid = @(cid % 256ULL);
        }
    } else if (result.eci != nil && result.enbid == nil) {
        unsigned long long eci = result.eci.unsignedLongLongValue;
        result.enbid = @(eci / 256ULL);
        if (result.cid == nil) {
            result.cid = @(eci % 256ULL);
        }
    }
}

static NSString *CellProbeFormatBandInfo(CTBandInfo *bandInfo) {
    if (bandInfo == nil) {
        return nil;
    }

    id activeBands = [bandInfo activeBands];
    if (activeBands != nil) {
        return CellProbeStringValue(activeBands);
    }

    if ([bandInfo respondsToSelector:@selector(activeBandsForRat:)]) {
        for (NSString *rat in @[@"NR", @"LTE", @"WCDMA", @"GSM"]) {
            id bands = [bandInfo activeBandsForRat:rat];
            if (bands != nil) {
                return [NSString stringWithFormat:@"%@: %@", rat, CellProbeStringValue(bands)];
            }
        }
    }

    return nil;
}

static void CellProbePrimeTelephonyCache(CTTelephonyNetworkInfo *networkInfo) {
    SEL initPrivate = NSSelectorFromString(@"tryInitPrivateFunctionality");
    SEL queryCells = NSSelectorFromString(@"queryCellIds");
    SEL queryRat = NSSelectorFromString(@"queryRat");

    if ([networkInfo respondsToSelector:initPrivate]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [networkInfo performSelector:initPrivate];
#pragma clang diagnostic pop
    }

    if ([networkInfo respondsToSelector:queryCells]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [networkInfo performSelector:queryCells];
#pragma clang diagnostic pop
    }

    if ([networkInfo respondsToSelector:queryRat]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [networkInfo performSelector:queryRat];
#pragma clang diagnostic pop
    }
}

@implementation CellProbeService

+ (instancetype)shared {
    static CellProbeService *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CellProbeService alloc] init];
    });
    return instance;
}

- (void)fillCarrierInfo:(CellProbeResult *)result networkInfo:(CTTelephonyNetworkInfo *)networkInfo {
    NSString *preferredService = networkInfo.dataServiceIdentifier;
    NSDictionary<NSString *, CTCarrier *> *providers = networkInfo.serviceSubscriberCellularProviders;
    CTCarrier *carrier = nil;

    if (preferredService.length > 0) {
        carrier = providers[preferredService];
    }

    if (carrier == nil) {
        carrier = providers.allValues.firstObject;
    }

    if (carrier != nil) {
        result.carrier = carrier.carrierName;
        result.mcc = carrier.mobileCountryCode;
        result.mnc = carrier.mobileNetworkCode;
    }

    NSDictionary<NSString *, NSString *> *ratMap = networkInfo.serviceCurrentRadioAccessTechnology;
    if (preferredService.length > 0) {
        result.radioAccessTechnology = ratMap[preferredService];
    }
    if (result.radioAccessTechnology.length == 0) {
        result.radioAccessTechnology = ratMap.allValues.firstObject;
    }
}

- (CellProbeResult *)fetchServingCellInfo {
    CellProbeResult *result = [[CellProbeResult alloc] init];
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    [self fillCarrierInfo:result networkInfo:networkInfo];

    CoreTelephonyClient *client = [[CoreTelephonyClient alloc] init];
    if (client == nil) {
        result.statusMessage = @"Không khởi tạo được CoreTelephonyClient.";
        return result;
    }

    CellProbePrimeTelephonyCache(networkInfo);

    NSError *contextError = nil;
    CTXPCServiceSubscriptionContext *context = [client getPreferredDataSubscriptionContextSync:&contextError];
    if (context == nil) {
        context = [CTXPCServiceSubscriptionContext contextWithSlot:1];
    }

    CTServiceDescriptor *descriptor = [CTServiceDescriptor descriptorWithSubscriptionContext:context];
    if (descriptor == nil) {
        descriptor = [CTServiceDescriptor telephonyDescriptorWithInstance:@(context.slotID)];
    }

    NSError *ratError = nil;
    NSString *rat = [client copyRadioAccessTechnology:context error:&ratError];
    if (rat.length > 0) {
        result.radioAccessTechnology = rat;
    }

    NSError *cellIdError = nil;
    CTCellIdInfo *cellIdInfo = [client copyPublicCellId:descriptor error:&cellIdError];
    if (cellIdInfo != nil) {
        result.cid = cellIdInfo.cellId;
        result.enbid = cellIdInfo.baseId;
    } else if (cellIdError != nil) {
        result.statusMessage = cellIdError.localizedDescription;
    }

    if (@available(iOS 14.0, *)) {
        NSError *bandError = nil;
        CTBandInfo *bandInfo = [client getBandInfo:context error:&bandError];
        result.band = CellProbeFormatBandInfo(bandInfo);
    }

    __block CTCellInfo *cellInfo = nil;
    __block NSError *cellInfoError = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [client copyCellInfo:context completion:^(CTCellInfo *info, NSError *error) {
        cellInfo = info;
        cellInfoError = error;
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)));

    if (cellInfo.legacyInfo.count > 0) {
        result.rawCellInfo = [[cellInfo.legacyInfo description] copy];
        CellProbeApplyLegacyEntries(result, cellInfo.legacyInfo);
    } else if (cellInfoError != nil && result.statusMessage.length == 0) {
        result.statusMessage = cellInfoError.localizedDescription;
    }

    CellProbeFinalizeDerivedValues(result);

    if (result.carrier.length == 0 &&
        result.band.length == 0 &&
        result.cid == nil &&
        result.pci == nil &&
        result.eci == nil) {
        if (result.statusMessage.length == 0) {
            result.statusMessage = @"iOS không trả về dữ liệu cell. Thử cài bằng developer cert trên máy thật, tắt Wi‑Fi và bật dữ liệu di động.";
        }
    }

    return result;
}

@end
