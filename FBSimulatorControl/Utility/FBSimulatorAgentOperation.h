/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

#import <FBSimulatorControl/FBAgentLaunchStrategy.h>

NS_ASSUME_NONNULL_BEGIN

@class FBApplicationLaunchConfiguration;
@class FBProcessInfo;
@class FBProcessOutput;

/**
 The Termination Handle Type for an Agent.
 */
extern FBTerminationHandleType const FBTerminationHandleTypeSimulatorAgent;

/**
 An Operation for an Agent.
 This class is explicitly a reference type as it retains the File Handles that are used by the Agent Process.
 The lifecycle of the process is managed internally and this class should not be instantiated directly by consumers.
 */
@interface FBSimulatorAgentOperation : NSObject <FBTerminationAwaitable>

/**
 Extracts termination information for the provided process.

 @param statLoc the value from waitpid(2).
 @return YES if the termination is expected. NO otherwise.
 */
+ (BOOL)isExpectedTerminationForStatLoc:(int)statLoc;

/**
 The Configuration Launched with.
 */
@property (nonatomic, copy, readonly) FBAgentLaunchConfiguration *configuration;

/**
 A future represnetation of this operation.
 The value of the future is the stat_loc value.
 */
@property (nonatomic, strong, readonly) FBFuture<NSNumber *> *future;

/**
 The stdout File Handle.
 */
@property (nonatomic, strong, nullable, readonly) FBProcessOutput *stdOut;

/**
 The stderr File Handle.
 */
@property (nonatomic, strong, nullable, readonly) FBProcessOutput *stdErr;

/**
 The Launched Process Info.
 */
@property (nonatomic, copy, nullable, readonly) FBProcessInfo *process;

@end

/**
 Private methods that should not be called by consumers.
 */
@interface FBSimulatorAgentOperation (Private)

/**
 The Designated Initializer.

 @param simulator the Simulator the Agent is launched in.
 @param configuration the configuration the process was launched with.
 @param stdOut the Stdout output.
 @param stdErr the Stderr output.
 @param completionFuture a future that will fire when the process has terminated. The value is the exit code.
 */
+ (instancetype)operationWithSimulator:(FBSimulator *)simulator configuration:(FBAgentLaunchConfiguration *)configuration stdOut:(nullable FBProcessOutput *)stdOut stdErr:(nullable FBProcessOutput *)stdErr completionFuture:(FBFuture<NSNumber *> *)completionFuture;

/**
 Called internally by the framework when the owning process has been launched.
 This should never be called by consumers.

 @param process the process info of the launched process.
 */
- (void)processDidLaunch:(FBProcessInfo *)process;

@end

NS_ASSUME_NONNULL_END
