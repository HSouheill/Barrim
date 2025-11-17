import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

Completer<void>? _loaderCompleter;

bool _isGoogleMapsLoaded() {
  if (!js_util.hasProperty(html.window, 'google')) return false;
  final googleObj = js_util.getProperty(html.window, 'google');
  return js_util.hasProperty(googleObj, 'maps');
}

Future<void> ensureGoogleMapsScriptLoaded(String apiKey) {
  if (_isGoogleMapsLoaded()) {
    return Future.value();
  }

  if (_loaderCompleter != null) {
    return _loaderCompleter!.future;
  }

  _loaderCompleter = Completer<void>();

  final existingScript = html.document.querySelector('script[data-google-maps-sdk]');
  if (existingScript != null) {
    existingScript.onLoad.first.then((_) {
      if (_isGoogleMapsLoaded()) {
        _loaderCompleter?.complete();
      } else {
        _loaderCompleter?.completeError('Google Maps JavaScript SDK failed to initialize.');
      }
    }).catchError((Object error, StackTrace stackTrace) {
      _loaderCompleter?.completeError(error, stackTrace);
    });
    return _loaderCompleter!.future;
  }

  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places'
    ..type = 'text/javascript'
    ..defer = true
    ..async = true
    ..dataset['googleMapsSdk'] = 'true';

  script.onError.listen((event) {
    _loaderCompleter?.completeError(
      'Failed to load Google Maps JavaScript SDK. Please verify the API key and network connectivity.',
    );
  });

  script.onLoad.listen((event) {
    if (_isGoogleMapsLoaded()) {
      _loaderCompleter?.complete();
    } else {
      _loaderCompleter?.completeError(
        'Google Maps JavaScript SDK loaded but window.google.maps is unavailable.',
      );
    }
  });

  html.document.head?.append(script);

  return _loaderCompleter!.future;
}

