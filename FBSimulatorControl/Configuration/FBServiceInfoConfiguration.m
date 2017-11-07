/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBServiceInfoConfiguration.h"

#import "FBSimulator.h"
#import "FBSimulator+Private.h"
#import "FBSimulatorProcessFetcher.h"
#import "FBSimulatorLaunchCtlCommands.h"

FBiOSTargetActionType const FBiOSTargetActionTypeServiceInfo = @"service_info";

@implementation FBServiceInfoConfiguration

#pragma mark Initializer

+ (instancetype)configurationWithServiceName:(NSString *)serviceName
{
  return [[self alloc] initWithServiceName:serviceName];
}

- (instancetype)initWithServiceName:(NSString *)serviceName
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _serviceName = serviceName;

  return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

#pragma mark NSObject

- (BOOL)isEqual:(FBServiceInfoConfiguration *)object
{
  if (![object isKindOfClass:self.class]) {
    return NO;
  }
  return [self.serviceName isEqualToString:object.serviceName];
}

- (NSUInteger)hash
{
  return self.serviceName.hash;
}

#pragma mark JSON

static NSString *const KeyServiceName = @"service_name";

+ (instancetype)inflateFromJSON:(NSDictionary<NSString *, id> *)json error:(NSError **)error
{
  if (![FBCollectionInformation isDictionaryHeterogeneous:json keyClass:NSString.class valueClass:NSString.class]) {
    return [[FBControlCoreError
      describeFormat:@"%@ is not a Dictionary<String, String>", json]
      fail:error];
  }
  NSString *serviceName = json[KeyServiceName];
  if (![serviceName isKindOfClass:NSString.class]) {
    return [[FBControlCoreError
      describeFormat:@"%@ is not a String for %@", serviceName, KeyServiceName]
      fail:error];
  }
  return [[self alloc] initWithServiceName:serviceName];
}

- (id)jsonSerializableRepresentation
{
  return @{
    KeyServiceName: self.serviceName,
  };
}

#pragma mark FBiOSTargetFuture

- (FBiOSTargetActionType)actionType
{
  return FBiOSTargetActionTypeServiceInfo;
}

- (FBFuture<FBiOSTargetActionType> *)runWithTarget:(id<FBiOSTarget>)target consumer:(id<FBFileConsumer>)consumer reporter:(id<FBEventReporter>)reporter
{
  id<FBSimulatorLaunchCtlCommands> commands = (id<FBSimulatorLaunchCtlCommands>) target;
  if (![commands conformsToProtocol:@protocol(FBSimulatorLaunchCtlCommands)]) {
    return [[FBControlCoreError
      describeFormat:@"%@ does not conform to FBSimulatorLaunchCtlCommands", target]
      failFuture];
  }
  FBProcessFetcher *processFetcher = [[(FBSimulator *)target processFetcher] processFetcher];
  return [[[[commands
    serviceNameAndProcessIdentifierForSubstring:self.serviceName]
    onQueue:target.workQueue fmap:^(NSArray<id> *tuple) {
      NSNumber *processIdentifier = tuple[1];
      FBProcessInfo *processInfo = [processFetcher processInfoFor:processIdentifier.intValue];
      if (!processInfo) {
        return [[FBControlCoreError
          describeFormat:@"Could not fetch process info for %@", [FBCollectionInformation oneLineDescriptionFromArray:tuple]]
          failFuture];
      }
      return [FBFuture futureWithResult:processInfo];
    }]
    onQueue:target.workQueue notifyOfCompletion:^(FBFuture<FBProcessInfo *> *future) {
      FBProcessInfo *processInfo = future.result;
      if (!processInfo) {
       return;
      }
      id<FBEventReporterSubject> coreSubject = [FBEventReporterSubject subjectWithControlCoreValue:processInfo];
      id<FBEventReporterSubject> subject = [FBEventReporterSubject subjectWithName:FBiOSTargetActionTypeServiceInfo type:FBEventTypeDiscrete subject:coreSubject];
      [reporter report:subject];
    }]
    mapReplace:self.actionType];
}

@end