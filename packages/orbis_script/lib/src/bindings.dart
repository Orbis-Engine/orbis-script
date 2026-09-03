// Raw FFI bindings to the shim. Nothing here manages lifetime or converts
// errors — that is [ScriptHost]'s job, and keeping the two apart means the
// generated binding tables in S2 can sit beside this file without tangling.

import 'dart:ffi';

const String kOrbisScriptAsset = 'package:orbis_script/orbis_script';

/// Opaque runtime-plus-context pair owned by the shim.
final class OrbisScriptHostStruct extends Opaque {}

@Native<Pointer<OrbisScriptHostStruct> Function()>(
    symbol: 'orbis_script_new', assetId: kOrbisScriptAsset)
external Pointer<OrbisScriptHostStruct> orbisScriptNew();

@Native<Void Function(Pointer<OrbisScriptHostStruct>)>(
    symbol: 'orbis_script_free', assetId: kOrbisScriptAsset)
external void orbisScriptFree(Pointer<OrbisScriptHostStruct> host);

@Native<
    Int Function(Pointer<OrbisScriptHostStruct>, Pointer<Char>, Pointer<Char>,
        Pointer<Pointer<Char>>)>(
    symbol: 'orbis_script_eval', assetId: kOrbisScriptAsset)
external int orbisScriptEval(
  Pointer<OrbisScriptHostStruct> host,
  Pointer<Char> source,
  Pointer<Char> fileName,
  Pointer<Pointer<Char>> out,
);

@Native<Int Function(Pointer<OrbisScriptHostStruct>, Pointer<Pointer<Char>>)>(
    symbol: 'orbis_script_pump', assetId: kOrbisScriptAsset)
external int orbisScriptPump(
  Pointer<OrbisScriptHostStruct> host,
  Pointer<Pointer<Char>> errorOut,
);

@Native<Void Function(Pointer<Char>)>(
    symbol: 'orbis_script_string_free', assetId: kOrbisScriptAsset)
external void orbisScriptStringFree(Pointer<Char> s);

@Native<Pointer<Char> Function()>(
    symbol: 'orbis_script_engine_version', assetId: kOrbisScriptAsset)
external Pointer<Char> orbisScriptEngineVersion();
