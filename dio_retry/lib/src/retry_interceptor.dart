
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'extra.dart';

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {

  final Dio dio;
  final Logger logger;
  final RetryInterceptorRequestExtra options;

  RetryInterceptor({ @required this.dio, this.logger, RetryInterceptorRequestExtra options}) :
  this.options = options ?? const RetryInterceptorRequestExtra();
  
  @override
  onError(DioError err) async {

    var extra = RetryInterceptorRequestExtra.fromExtra(err.request) ?? this.options;

    if(extra.retries > 0) {
      if(extra.retryInterval.inMilliseconds > 0) {
        await Future.delayed(extra.retryInterval);
      }

      // Update options to decrease retry count before new try
      extra = extra.copyWith(retries: extra.retries - 1);
      err.request.extra = err.request.extra..addAll(extra.toExtra());

      try {
        logger?.warning(
            "[${err.request.uri}] An error occured during request, trying a again (remaining tries: ${extra.retries}, error: ${err.error})");
        // We retry with the updated options
        return await this.dio.request(err.request.path,
          cancelToken: err.request.cancelToken,
          data: err.request.data,
          onReceiveProgress: err.request.onReceiveProgress,
          onSendProgress: err.request.onSendProgress,
          queryParameters: err.request.queryParameters,
          options: err.request,
        );
      }
      catch(e) {
        return e;
      }
    }
    
    return super.onError(err);
  }
}