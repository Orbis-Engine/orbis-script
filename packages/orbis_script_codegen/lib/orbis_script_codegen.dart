/// Generates TypeScript typings from Orbis component manifests.
library;

export 'src/manifest.dart'
    show ManifestComponent, ManifestError, ManifestReader;
export 'src/typescript_emitter.dart' show TypeScriptEmitter;
