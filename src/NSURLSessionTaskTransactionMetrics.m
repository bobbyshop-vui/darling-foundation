#import <Foundation/NSURLSessionTaskTransactionMetrics.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLResponse.h>

@interface NSURLSessionTaskTransactionMetrics ()
@property (copy, readwrite) NSURLRequest *request;
@property (copy, readwrite) NSURLResponse *response;
@property (copy, readwrite) NSDate *fetchStartDate;
@property (copy, readwrite) NSDate *domainLookupStartDate;
@property (copy, readwrite) NSDate *domainLookupEndDate;
@property (copy, readwrite) NSDate *connectStartDate;
@property (copy, readwrite) NSDate *secureConnectionStartDate;
@property (copy, readwrite) NSDate *secureConnectionEndDate;
@property (copy, readwrite) NSDate *connectEndDate;
@property (copy, readwrite) NSDate *requestStartDate;
@property (copy, readwrite) NSDate *requestEndDate;
@property (copy, readwrite) NSDate *responseStartDate;
@property (copy, readwrite) NSDate *responseEndDate;
@property (copy, readwrite) NSString *networkProtocolName;
@property (assign, readwrite, getter=isProxyConnection) BOOL proxyConnection;
@property (assign, readwrite, getter=isReusedConnection) BOOL reusedConnection;
@property (assign, readwrite) NSURLSessionTaskMetricsResourceFetchType resourceFetchType;
@end

@implementation NSURLSessionTaskTransactionMetrics

@synthesize request = _request;
@synthesize response = _response;
@synthesize fetchStartDate = _fetchStartDate;
@synthesize domainLookupStartDate = _domainLookupStartDate;
@synthesize domainLookupEndDate = _domainLookupEndDate;
@synthesize connectStartDate = _connectStartDate;
@synthesize secureConnectionStartDate = _secureConnectionStartDate;
@synthesize secureConnectionEndDate = _secureConnectionEndDate;
@synthesize connectEndDate = _connectEndDate;
@synthesize requestStartDate = _requestStartDate;
@synthesize requestEndDate = _requestEndDate;
@synthesize responseStartDate = _responseStartDate;
@synthesize responseEndDate = _responseEndDate;
@synthesize networkProtocolName = _networkProtocolName;
@synthesize proxyConnection = _proxyConnection;
@synthesize reusedConnection = _reusedConnection;
@synthesize resourceFetchType = _resourceFetchType;

- (instancetype)init
{
    return [self initWithRequest:nil response:nil];
}

- (instancetype)initWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response
{
    if ((self = [super init])) {
        _request = [request copy];
        _response = [response copy];
        _resourceFetchType = NSURLSessionTaskMetricsResourceFetchTypeUnknown;
    }
    return self;
}

- (void)dealloc
{
    [_request release];
    [_response release];
    [_fetchStartDate release];
    [_domainLookupStartDate release];
    [_domainLookupEndDate release];
    [_connectStartDate release];
    [_secureConnectionStartDate release];
    [_secureConnectionEndDate release];
    [_connectEndDate release];
    [_requestStartDate release];
    [_requestEndDate release];
    [_responseStartDate release];
    [_responseEndDate release];
    [_networkProtocolName release];
    [super dealloc];
}

@end
