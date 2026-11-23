/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSUndoGroup.h>
#import <Foundation/NSUndoManager.h>
#import <Foundation/NSValue.h>
#import <Block.h>

enum _NSUndoManagerState {
    NSUndoManagerNormal,
    NSUndoManagerUndoing,
    NSUndoManagerRedoing
};

NSString *const NSUndoManagerCheckpointNotification =
        @"NSUndoManagerCheckpointNotification";
NSString *const NSUndoManagerDidOpenUndoGroupNotification =
        @"NSUndoManagerDidOpenUndoGroupNotification";
NSString *const NSUndoManagerWillCloseUndoGroupNotification =
        @"NSUndoManagerWillCloseUndoGroupNotification";
NSString *const NSUndoManagerDidCloseUndoGroupNotification =
        @"NSUndoManagerDidCloseUndoGroupNotification";
NSString *const NSUndoManagerWillUndoChangeNotification =
        @"NSUndoManagerWillUndoChangeNotification";
NSString *const NSUndoManagerDidUndoChangeNotification =
        @"NSUndoManagerDidUndoChangeNotification";
NSString *const NSUndoManagerWillRedoChangeNotification =
        @"NSUndoManagerWillRedoChangeNotification";
NSString *const NSUndoManagerDidRedoChangeNotification =
        @"NSUndoManagerDidRedoChangeNotification";

static NSHashTable *mainThreadPendingUndoManagers;

@interface _NSUndoManagerBlockAction : NSObject {
    id _target;
    void (^_handler)(id);
}
- (id)initWithTarget:(id)target handler:(void (^)(id))handler;
- (void)invokeUndoHandler;
@end

@implementation _NSUndoManagerBlockAction
- (id)initWithTarget:(id)target handler:(void (^)(id))handler
{
    self = [super init];
    if (self) {
        _target = target;
        _handler = Block_copy(handler);
    }
    return self;
}

- (void)invokeUndoHandler
{
    if (_handler != nil)
        _handler(_target);
}

- (void)dealloc
{
    if (_handler != nil)
        Block_release(_handler);
    [super dealloc];
}
@end

@interface NSUndoManager (Discardability)
- (void)_removeDiscardableInvocationsInGroup:(NSUndoGroup *)group;
- (void)_removeDiscardableInvocationsInGroup:(NSUndoGroup *)group target:(id)target;
- (void)_removeDiscardableInvocationsInGroups:(NSArray *)groups;
- (void)_setDiscardableInvocationsInGroup:(NSUndoGroup *)group discardable:(BOOL)discardable;
- (BOOL)_isDiscardableGroup:(NSUndoGroup *)group;
@end

@implementation NSUndoManager

+ (void) _endTopLevelGroupings {
    if (![NSThread isMainThread]) {
        [NSException raise: NSInternalInconsistencyException
                    format: @"_endTopLevelGroupings must run on the main thread"];
    }

    for (NSUndoManager *manager in [mainThreadPendingUndoManagers allObjects]) {
        if (manager->_performRegistered && manager->_groupsByEvent &&
            manager->_state == NSUndoManagerNormal && [manager groupingLevel] == 1) {
            [manager _unregisterPerform];
            [manager endUndoGrouping];
        }
    }
}

- (void) _registerPerform {
    if (!_performRegistered) {
        _performRegistered = YES;
        [[NSRunLoop currentRunLoop]
                performSelector: @selector(runLoopUndo:)
                         target: self
                       argument: nil
                          order: NSUndoCloseGroupingRunLoopOrdering
                          modes: _modes];

        if ([NSThread isMainThread]) {
            if (mainThreadPendingUndoManagers == nil) {
                mainThreadPendingUndoManagers = [[NSHashTable alloc]
                        initWithOptions: NSPointerFunctionsWeakMemory |
                                         NSPointerFunctionsObjectPointerPersonality
                               capacity: 0];
            }
            [mainThreadPendingUndoManagers addObject: self];
        }
    }
}

- (void) _clearPerformRegistration {
    _performRegistered = NO;
    if ([NSThread isMainThread])
        [mainThreadPendingUndoManagers removeObject: self];
}

- (void) _unregisterPerform {
    if (_performRegistered) {
        [self _clearPerformRegistration];
        [[NSRunLoop currentRunLoop]
                cancelPerformSelector: @selector(runLoopUndo:)
                               target: self
                             argument: nil];
    }
}

- (id) init {
    _undoStack = [[NSMutableArray alloc] init];
    _redoStack = [[NSMutableArray alloc] init];
    _discardableInvocations = [[NSMutableSet alloc] init];
    _state = NSUndoManagerNormal;

    [self setRunLoopModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
    [self setGroupsByEvent: YES];

    return self;
}

- (void) dealloc {
    [self _unregisterPerform];

    [_undoStack release];
    [_redoStack release];
    [_discardableInvocations release];
    [_currentGroup release];
    [_modes release];
    [_actionName release];

    [super dealloc];
}

- (void)_removeDiscardableInvocationsInGroup:(NSUndoGroup *)group
{
    for (NSInvocation *invocation in [group invocations])
        [_discardableInvocations removeObject:[NSValue valueWithPointer:invocation]];
}

- (void)_removeDiscardableInvocationsInGroup:(NSUndoGroup *)group target:(id)target
{
    for (NSInvocation *invocation in [group invocations]) {
        if ([invocation target] == target)
            [_discardableInvocations removeObject:[NSValue valueWithPointer:invocation]];
    }
}

- (void)_removeDiscardableInvocationsInGroups:(NSArray *)groups
{
    for (NSUndoGroup *group in groups)
        [self _removeDiscardableInvocationsInGroup:group];
}

- (void)_setDiscardableInvocationsInGroup:(NSUndoGroup *)group discardable:(BOOL)discardable
{
    for (NSInvocation *invocation in [group invocations]) {
        NSValue *key = [NSValue valueWithPointer:invocation];
        if (discardable)
            [_discardableInvocations addObject:key];
        else
            [_discardableInvocations removeObject:key];
    }
}

- (BOOL)_isDiscardableGroup:(NSUndoGroup *)group
{
    NSArray *invocations = [group invocations];
    if ([invocations count] == 0)
        return NO;

    for (NSInvocation *invocation in invocations) {
        if (![_discardableInvocations containsObject:[NSValue valueWithPointer:invocation]])
            return NO;
    }
    return YES;
}

- (NSArray *) runLoopModes {
    return _modes;
}

- (NSUInteger) levelsOfUndo {
    return _levelsOfUndo;
}

- (BOOL) groupsByEvent {
    return _groupsByEvent;
}

- (void) setRunLoopModes: (NSArray *) modes {
    [_modes release];
    _modes = [modes retain];
    [self _unregisterPerform];
    if (_groupsByEvent)
        [self _registerPerform];
}

- (void) setLevelsOfUndo: (NSUInteger) levels {
    _levelsOfUndo = levels;
    while ([_undoStack count] > _levelsOfUndo) {
        [self _removeDiscardableInvocationsInGroup:[_undoStack objectAtIndex:0]];
        [_undoStack removeObjectAtIndex: 0];
    }
    while ([_redoStack count] > _levelsOfUndo) {
        [self _removeDiscardableInvocationsInGroup:[_redoStack objectAtIndex:0]];
        [_redoStack removeObjectAtIndex: 0];
    }
}

- (void) setGroupsByEvent: (BOOL) flag {
    _groupsByEvent = flag;
    if (_groupsByEvent)
        [self _registerPerform];
    else
        [self _unregisterPerform];
}

- (BOOL) isUndoRegistrationEnabled {
    return (_disableCount == 0);
}

- (void) disableUndoRegistration {
    _disableCount++;
}

- (void) enableUndoRegistration {
    if (_disableCount == 0)
        [NSException raise: NSInternalInconsistencyException
                    format: @"Attempt to enable registration with no disable "
                            @"message in effect"];

    _disableCount--;
}

- (void) beginUndoGrouping {
    NSUndoGroup *undoGroup =
            [NSUndoGroup undoGroupWithParentGroup: _currentGroup];

    if (!([_currentGroup parentGroup] == nil && _state == NSUndoManagerUndoing))
        [[NSNotificationCenter defaultCenter]
                postNotificationName: NSUndoManagerCheckpointNotification
                              object: self];

    [_currentGroup release];
    _currentGroup = [undoGroup retain];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerDidOpenUndoGroupNotification
                          object: self];
}

- (void) endUndoGrouping {
    NSMutableArray *stack = nil;
    NSUndoGroup *parentGroup = [[_currentGroup parentGroup] retain];

    if (_currentGroup == nil)
        [NSException raise: NSInternalInconsistencyException
                    format: @"endUndoGrouping called without first calling "
                            @"beginUndoGrouping"];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerCheckpointNotification
                          object: self];

    if (parentGroup == nil && [[_currentGroup invocations] count] > 0) {
        switch (_state) {
        case NSUndoManagerNormal:
            [[NSNotificationCenter defaultCenter]
                    postNotificationName:
                            NSUndoManagerWillCloseUndoGroupNotification
                                  object: self];

        case NSUndoManagerRedoing:
            stack = _undoStack;
            break;

        case NSUndoManagerUndoing:
            stack = _redoStack;
            break;
        }

        [stack addObject: _currentGroup];
        if (_levelsOfUndo > 0)
            if ([stack count] > _levelsOfUndo)
                [stack removeObjectAtIndex: 0];
    } else {
        // a nested group was closed. fold its invocations into its parent,
        // preserving the order for future changes on the parent.
        [parentGroup addInvocationsFromArray: [_currentGroup invocations]];
    }

    [_currentGroup release];
    _currentGroup = parentGroup;
}

- (NSInteger) groupingLevel {
    NSUndoGroup *temp = _currentGroup;
    int level = (_currentGroup != nil);

    while ((temp = [temp parentGroup]) != nil)
        level++;

    return level;
}

- (void) runLoopUndo: (id) dummy {
    if (!_performRegistered)
        return;

    [self _clearPerformRegistration];
    if (_groupsByEvent && _currentGroup != nil)
        [self endUndoGrouping];
}

- (BOOL) canUndo {
    if ([_undoStack count] > 0)
        return YES;

    if ([[_currentGroup invocations] count] > 0)
        return YES;

    return NO;
}

- (void) undoNestedGroup {
    NSUndoGroup *undoGroup;
    BOOL wasDiscardable;

    if (_currentGroup != nil)
        [NSException raise: NSInternalInconsistencyException
                    format: @"undo called with open nested group"];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerCheckpointNotification
                          object: self];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerWillUndoChangeNotification
                          object: self];

    _state = NSUndoManagerUndoing;
    undoGroup = [[_undoStack lastObject] retain];
    [_undoStack removeLastObject];
    wasDiscardable = [self _isDiscardableGroup:undoGroup];
    [self _removeDiscardableInvocationsInGroup:undoGroup];
    [self beginUndoGrouping];
    [undoGroup invokeInvocations];
    if (wasDiscardable)
        [self _setDiscardableInvocationsInGroup:_currentGroup discardable:YES];
    [self endUndoGrouping];
    [undoGroup release];
    _state = NSUndoManagerNormal;

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerDidUndoChangeNotification
                          object: self];
}

- (void) undo {
    if ([self groupingLevel] == 1)
        [self endUndoGrouping];

    [self undoNestedGroup];
}

- (BOOL) isUndoing {
    return (_state == NSUndoManagerUndoing);
}

- (BOOL) canRedo {
    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerCheckpointNotification
                          object: self];
    return ([_redoStack count] > 0);
}

- (void) redo {
    NSUndoGroup *undoGroup;
    BOOL wasDiscardable;

    if (_state == NSUndoManagerUndoing)
        [NSException raise: NSInternalInconsistencyException
                    format: @"redo called while undoing"];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerCheckpointNotification
                          object: self];

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerWillRedoChangeNotification
                          object: self];

    _state = NSUndoManagerRedoing;
    undoGroup = [[_redoStack lastObject] retain];
    [_redoStack removeLastObject];
    wasDiscardable = [self _isDiscardableGroup:undoGroup];
    [self _removeDiscardableInvocationsInGroup:undoGroup];
    [self beginUndoGrouping];
    [undoGroup invokeInvocations];
    if (wasDiscardable)
        [self _setDiscardableInvocationsInGroup:_currentGroup discardable:YES];
    [self endUndoGrouping];
    [undoGroup release];
    _state = NSUndoManagerNormal;

    [[NSNotificationCenter defaultCenter]
            postNotificationName: NSUndoManagerDidRedoChangeNotification
                          object: self];
}

- (BOOL) isRedoing {
    return (_state == NSUndoManagerRedoing);
}

- (void) registerUndoWithTarget: (id) target
                       selector: (SEL) selector
                         object: (id) object
{
    NSInvocation *invocation;
    NSMethodSignature *signature;

    if (_disableCount > 0)
        return;

    if (_groupsByEvent && _currentGroup == nil) {
        [self _registerPerform];
        [self beginUndoGrouping];
    }

    if (_currentGroup == nil)
        [NSException raise: NSInternalInconsistencyException
                    format: @"forwardInvocation called without first opening "
                            @"an undo group"];

    signature = [target methodSignatureForSelector: selector];
    invocation = [NSInvocation invocationWithMethodSignature: signature];

    [invocation setTarget: target];
    [invocation setSelector: selector];
    [invocation setArgument: &object atIndex: 2];
    [invocation retainArguments];

    [_currentGroup addInvocation: invocation];

    if (_state == NSUndoManagerNormal) {
        [self _removeDiscardableInvocationsInGroups:_redoStack];
        [_redoStack removeAllObjects];
    }
}

- (void)registerUndoWithTarget:(id)target handler:(void (^)(id))undoHandler
{
    if (_disableCount > 0)
        return;
    if (target == nil || undoHandler == nil)
        [NSException raise:NSInvalidArgumentException format:@"Undo target and handler must not be nil"];

    if (_groupsByEvent && _currentGroup == nil) {
        [self _registerPerform];
        [self beginUndoGrouping];
    }
    if (_currentGroup == nil)
        [NSException raise:NSInternalInconsistencyException
                    format:@"registerUndoWithTarget:handler: called without an open undo group"];

    _NSUndoManagerBlockAction *action = [[_NSUndoManagerBlockAction alloc] initWithTarget:target handler:undoHandler];
    NSMethodSignature *signature = [action methodSignatureForSelector:@selector(invokeUndoHandler)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:action];
    [invocation setSelector:@selector(invokeUndoHandler)];
    [invocation retainArguments];
    [_currentGroup addInvocation:invocation];
    [action release];

    if (_state == NSUndoManagerNormal) {
        [self _removeDiscardableInvocationsInGroups:_redoStack];
        [_redoStack removeAllObjects];
    }
}

- (void)setActionIsDiscardable:(BOOL)discardable
{
    NSUndoGroup *group = _currentGroup;
    if ([group invocations] == nil || [[group invocations] count] == 0)
        group = [_undoStack lastObject];
    NSInvocation *invocation = [[group invocations] lastObject];
    if (invocation == nil)
        return;

    NSValue *key = [NSValue valueWithPointer:invocation];
    if (discardable)
        [_discardableInvocations addObject:key];
    else
        [_discardableInvocations removeObject:key];
}

- (BOOL)undoActionIsDiscardable
{
    NSUndoGroup *group = [[_currentGroup invocations] count] > 0
        ? _currentGroup
        : [_undoStack lastObject];
    return [self _isDiscardableGroup:group];
}

- (BOOL)redoActionIsDiscardable
{
    return [self _isDiscardableGroup:[_redoStack lastObject]];
}

- (void) removeAllActions {
    [_undoStack removeAllObjects];
    [_redoStack removeAllObjects];
    [self _removeDiscardableInvocationsInGroup:_currentGroup];
    [_discardableInvocations removeAllObjects];
    _disableCount = 0;
}

- (void) removeAllActionsWithTarget: (id) target {
    NSUndoGroup *undoGroup;
    int i;

    [self _removeDiscardableInvocationsInGroup:_currentGroup target:target];
    [_currentGroup removeInvocationsWithTarget: target];

    for (i = 0; i < [_undoStack count]; ++i) {
        undoGroup = [_undoStack objectAtIndex: i];

        [self _removeDiscardableInvocationsInGroup:undoGroup target:target];
        [undoGroup removeInvocationsWithTarget: target];
        if ([[undoGroup invocations] count] == 0)
            [_undoStack removeObject: undoGroup];
    }
    for (i = 0; i < [_redoStack count]; ++i) {
        undoGroup = [_redoStack objectAtIndex: i];

        [self _removeDiscardableInvocationsInGroup:undoGroup target:target];
        [undoGroup removeInvocationsWithTarget: target];
        if ([[undoGroup invocations] count] == 0)
            [_redoStack removeObject: undoGroup];
    }
}

- (id) prepareWithInvocationTarget: (id) target {
    _preparedTarget = [target retain];

    return self;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) selector {
    return [_preparedTarget methodSignatureForSelector: selector];
}

- (void) forwardInvocation: (NSInvocation *) invocation {
    if (_disableCount > 0)
        return;

    if (_preparedTarget == nil)
        [NSException raise: NSInternalInconsistencyException
                    format: @"forwardInvocation called without first preparing "
                            @"a target"];

    if (_groupsByEvent && _currentGroup == nil) {
        [self _registerPerform];
        [self beginUndoGrouping];
    }

    if (_currentGroup == nil)
        [NSException raise: NSInternalInconsistencyException
                    format: @"forwardInvocation called without first opening "
                            @"an undo group"];

    [invocation setTarget: _preparedTarget];
    [_currentGroup addInvocation: invocation];
    [invocation retainArguments];

    if (_state == NSUndoManagerNormal) {
        [self _removeDiscardableInvocationsInGroups:_redoStack];
        [_redoStack removeAllObjects];
    }

    [_preparedTarget release];
    _preparedTarget = nil;
}

- (void) setActionName: (NSString *) name {
    [_actionName release];
    _actionName = [name retain];
}

- (NSString *) undoActionName {
    if ([self canUndo])
        return _actionName;

    return nil;
}

- (NSString *) undoMenuItemTitle {
    return [self undoMenuTitleForUndoActionName: [self undoActionName]];
}

// needs localization
- (NSString *) undoMenuTitleForUndoActionName: (NSString *) name {
    if (name != nil) {
        if ([name length] > 0)
            return [NSString stringWithFormat: @"Undo %@", name];

        return @"Undo";
    }

    return name;
}

- (NSString *) redoActionName {
    if ([self canRedo])
        return _actionName;

    return nil;
}

- (NSString *) redoMenuItemTitle {
    return [self redoMenuTitleForUndoActionName: [self redoActionName]];
}

- (NSString *) redoMenuTitleForUndoActionName: (NSString *) name {
    if (name != nil) {
        if ([name length] > 0)
            return [NSString stringWithFormat: @"Redo %@", name];

        return @"Redo";
    }

    return name;
}

- (void) clearRedoStackIfStateIsNormal {
    if (_state == NSUndoManagerNormal)
        [_redoStack removeAllObjects];
}

@end
