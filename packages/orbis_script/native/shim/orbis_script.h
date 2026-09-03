// The C surface the Dart host binds to over dart:ffi.
//
// Deliberately narrow and string-based at this stage: everything crossing the
// boundary is either a handle or a UTF-8 buffer the caller frees. Richer
// marshalling belongs above this, once the engine's own C ABI is what scripts
// are calling into.

#ifndef ORBIS_SCRIPT_H
#define ORBIS_SCRIPT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OrbisScriptHost OrbisScriptHost;

/// Creates a runtime and its first context. NULL if either allocation fails.
OrbisScriptHost *orbis_script_new(void);

/// Tears down the context and runtime. Safe on NULL.
void orbis_script_free(OrbisScriptHost *host);

/// Evaluates `src` as a global script.
///
/// Returns 0 when the script completed and 1 when it threw. Either way `*out`
/// receives a heap UTF-8 string the caller releases with
/// orbis_script_string_free: the result coerced to string on success, or the
/// error message followed by its JS stack on failure.
int orbis_script_eval(OrbisScriptHost *host, const char *src,
                      const char *filename, char **out);

/// Drains the microtask queue.
///
/// Returns the number of jobs run, or -1 on failure — in which case `*err_out`
/// receives the message and stack, as for orbis_script_eval.
///
/// Failure covers two cases that JavaScript keeps apart. A job may throw, which
/// QuickJS reports directly. A promise may also reject with nothing to catch
/// it, which QuickJS reports only through a tracker and would otherwise be
/// lost; this API treats that as a failure too, because a mod whose async work
/// died quietly is worse than one that stopped loudly.
int orbis_script_pump(OrbisScriptHost *host, char **err_out);

/// Releases a string handed back by this API.
void orbis_script_string_free(char *s);

/// The vendored QuickJS version, for surfacing in diagnostics.
const char *orbis_script_engine_version(void);

#ifdef __cplusplus
}
#endif

#endif  // ORBIS_SCRIPT_H
