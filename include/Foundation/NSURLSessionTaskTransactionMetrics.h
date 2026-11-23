#import <Foundation/NSObject.h>

@class NSDate, NSString, NSURLRequest, NSURLResponse;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NSURLSessionTaskMetricsResourceFetchType) {
    NSURLSessionTaskMetricsResourceFetchTypeUnknown,
    NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad,
    NSURLSessionTaskMetricsResourceFetchTypeServerPush,
    NSURLSessionTaskMetricsResourceFetchTypeLocalCache,
};

@interface NSURLSessionTaskTransactionMetrics : NSObject {
    NSURLRequest *_request;
    NSURLResponse *_response;
    NSDate *_fetchStartDate;
    NSDate *_domainLookupStartDate;
    NSDate *_domainLookupEndDate;
    NSDate *_connectStartDate;
    NSDate *_secureConnectionStartDate;
    NSDate *_secureConnectionEndDate;
    NSDate *_connectEndDate;
    NSDate *_requestStartDate;
    NSDate *_requestEndDate;
    NSDate *_responseStartDate;
    NSDate *_responseEndDate;
    NSString *_networkProtocolName;
    BOOL _proxyConnection;
    BOOL _reusedConnection;
    NSURLSessionTaskMetricsResourceFetchType _resourceFetchType;
}

@property (copy, readonly) NSURLRequest *request;
@property (nullable, copy, readonly) NSURLResponse *response;
@property (nullable, copy, readonly) NSDate *fetchStartDate;
@property (nullable, copy, readonly) NSDate *domainLookupStartDate;
@property (nullable, copy, readonly) NSDate *domainLookupEndDate;
@property (nullable, copy, readonly) NSDate *connectStartDate;
@property (nullable, copy, readonly) NSDate *secureConnectionStartDate;
@property (nullable, copy, readonly) NSDate *secureConnectionEndDate;
@property (nullable, copy, readonly) NSDate *connectEndDate;
@property (nullable, copy, readonly) NSDate *requestStartDate;
@property (nullable, copy, readonly) NSDate *requestEndDate;
@property (nullable, copy, readonly) NSDate *responseStartDate;
@property (nullable, copy, readonly) NSDate *responseEndDate;
@property (nullable, copy, readonly) NSString *networkProtocolName;
@property (assign, readonly, getter=isProxyConnection) BOOL proxyConnection;
@property (assign, readonly, getter=isReusedConnection) BOOL reusedConnection;
@property (assign, readonly) NSURLSessionTaskMetricsResourceFetchType resourceFetchType;

/* Darling: used by the URL loading system to build a record for one transaction. */
- (instancetype)initWithRequest:(NSURLRequest *)request response:(nullable NSURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
