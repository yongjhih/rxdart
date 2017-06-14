import 'dart:async';

import 'package:rxdart/src/utils/notification.dart';

/// Invokes the given callback at the corresponding point the the stream
/// lifecycle. For example, if you pass in an onDone callback, it will
/// be invoked when the stream finishes emitting items.
///
/// This transformer can be used for debugging, logging, etc. by intercepting
/// the stream at different points to run arbitrary actions.
///
/// It is possible to hook onto the following parts of the stream lifecycle:
///
///   - onCancel
///   - onData
///   - onDone
///   - onError
///   - onListen
///   - onPause
///   - onResume
///
/// In addition, the `onEach` argument is called at `onData`, `onDone`, and
/// `onError` with a [Notification] passed in. The [Notification] argument
/// contains the [Kind] of event (OnData, OnDone, OnError), and the item or
/// error that was emitted. In the case of onDone, no data is emitted as part
/// of the [Notification].
///
/// If no callbacks are passed in, a runtime error will be thrown in dev mode
/// in order to "fail fast" and alert the developer that the transformer should
/// be used or safely removed.
///
/// ### Example
///
///     new Stream.fromIterable([1])
///         .transform(new DoStreamTransformer(
///           onData: print,
///           onError: (e, s) => print("Oh no!"),
///           onDone: () => print("Done")))
///         .listen(null); // Prints: 1, "Done"
class DoStreamTransformer<T> implements StreamTransformer<T, T> {
  final StreamTransformer<T, T> transformer;

  DoStreamTransformer(
      {void onCancel(),
      void onData(T event),
      void onDone(),
      void onEach(Notification<T> notification),
      Function onError,
      void onListen(),
      void onPause(Future<dynamic> resumeSignal),
      void onResume()})
      : transformer = _buildTransformer(
            onCancel: onCancel,
            onData: onData,
            onDone: onDone,
            onEach: onEach,
            onError: onError,
            onListen: onListen,
            onPause: onPause,
            onResume: onResume);

  @override
  Stream<T> bind(Stream<T> stream) => transformer.bind(stream);

  static StreamTransformer<T, T> _buildTransformer<T>(
      {void onCancel(),
      void onData(T event),
      void onDone(),
      void onEach(Notification<T> notification),
      Function onError,
      void onListen(),
      void onPause(Future<dynamic> resumeSignal),
      void onResume()}) {
    assert(onCancel != null ||
        onData != null ||
        onDone != null ||
        onEach != null ||
        onError != null ||
        onListen != null ||
        onPause != null ||
        onResume != null);

    return new StreamTransformer<T, T>((Stream<T> input, bool cancelOnError) {
      StreamController<T> controller;
      StreamSubscription<T> subscription;

      controller = new StreamController<T>(
          sync: true,
          onListen: () {
            if (onListen != null) {
              try {
                onListen();
              } catch (e, s) {
                controller.addError(e, s);
              }
            }

            subscription = input.listen((T value) {
              if (onData != null) {
                try {
                  onData(value);
                } catch (e, s) {
                  controller.addError(e, s);
                }
              }

              if (onEach != null) {
                try {
                  onEach(new Notification<T>.onData(value));
                } catch (e, s) {
                  controller.addError(e, s);
                }
              }

              controller.add(value);
            }, onError: (dynamic e, dynamic s) {
              if (onError != null) {
                try {
                  onError(e, s);
                } catch (e2, s2) {
                  controller.addError(e2, s2);
                }
              }

              if (onEach != null) {
                try {
                  onEach(new Notification<T>.onError(e, s));
                } catch (e, s) {
                  controller.addError(e, s);
                }
              }

              controller.addError(e, s);
            }, onDone: () {
              if (onDone != null) {
                try {
                  onDone();
                } catch (e, s) {
                  controller.addError(e, s);
                }
              }

              if (onEach != null) {
                try {
                  onEach(new Notification<T>.onDone());
                } catch (e, s) {
                  controller.addError(e, s);
                }
              }

              controller.close();
            }, cancelOnError: cancelOnError);
          },
          onPause: ([Future<dynamic> resumeSignal]) {
            if (onPause != null) {
              try {
                onPause(resumeSignal);
              } catch (e, s) {
                controller.addError(e, s);
              }
            }

            subscription.pause(resumeSignal);
          },
          onResume: () {
            if (onResume != null) {
              try {
                onResume();
              } catch (e, s) {
                controller.addError(e, s);
              }
            }

            subscription.resume();
          },
          onCancel: () {
            if (onCancel != null) {
              try {
                onCancel();
              } catch (e, s) {
                if (!controller.isClosed) {
                  controller.addError(e, s);
                } else {
                  Zone.current.handleUncaughtError(e, s);
                }
              }
            }

            return subscription.cancel();
          });

      return controller.stream.listen(null);
    });
  }
}
