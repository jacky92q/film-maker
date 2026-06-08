import 'dart:js_interop';
import 'dart:typed_data';

@JS('filmMakerImageStore.store')
external JSPromise<JSAny?> _storeJS(JSString key, JSUint8Array bytes);

@JS('filmMakerImageStore.load')
external JSPromise<JSAny?> _loadJS(JSString key);

@JS('filmMakerImageStore.delete')
external JSPromise<JSAny?> _deleteJS(JSString key);

Future<void> webStoreImage(String key, Uint8List bytes) async {
  await _storeJS(key.toJS, bytes.toJS).toDart;
}

Future<Uint8List?> webLoadImage(String key) async {
  final result = await _loadJS(key.toJS).toDart;
  if (result == null || result.isUndefinedOrNull) return null;
  return (result as JSUint8Array).toDart;
}

Future<void> webDeleteImage(String key) async {
  await _deleteJS(key.toJS).toDart;
}
