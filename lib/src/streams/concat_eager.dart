import 'dart:async';

/// Concatenates all of the specified stream sequences, as long as the
/// previous stream sequence terminated successfully.
///
/// In the case of concatEager, rather than subscribing to one stream after
/// the next, all streams are immediately subscribed to. The events are then
/// captured and emitted at the correct time, after the previous stream has
/// finished emitting items.
///
/// [Interactive marble diagram](http://rxmarbles.com/#concat)
///
/// ### Example
///
///     new ConcatEagerStream([
///       new Stream.fromIterable([1]),
///       new TimerStream(2, new Duration(days: 1)),
///       new Stream.fromIterable([3])
///     ])
///     .listen(print); // prints 1, 2, 3
class ConcatEagerStream<T> extends Stream<T> {
  final StreamController<T> controller;

  ConcatEagerStream(Iterable<Stream<T>> streams)
      : controller = _buildController(streams);

  @override
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    final List<StreamSubscription<T>> subscriptions = streams != null
        ? new List<StreamSubscription<T>>(streams.length)
        : null;
    final List<Completer<dynamic>> completeEvents =
        streams != null ? new List<Completer<dynamic>>(streams.length) : null;
    StreamController<T> controller;

    controller = new StreamController<T>(
        sync: true,
        onListen: () {
          if (streams == null) {
            controller.addError(new ArgumentError('streams cannot be null'));
          } else if (streams.isEmpty) {
            controller.addError(
                new ArgumentError('at least 1 stream needs to be provided'));
          } else {
            for (int i = 0, len = streams.length; i < len; i++) {
              Stream<T> stream = streams.elementAt(i);

              if (stream == null) {
                controller.addError(
                    new ArgumentError('stream at position $i is Null'));
              } else {
                completeEvents[i] = new Completer<dynamic>();

                subscriptions[i] = streams.elementAt(i).listen(controller.add,
                    onError: controller.addError, onDone: () {
                  completeEvents[i].complete();

                  if (i == len - 1) controller.close();
                });

                if (i > 0) subscriptions[i].pause(completeEvents[i - 1].future);
              }
            }
          }
        },
        onCancel: () => Future.wait(subscriptions
            .map((StreamSubscription<T> subscription) => subscription.cancel())
            .where((Future<dynamic> cancelFuture) => cancelFuture != null)));

    return controller;
  }
}
