#include "orbis_script.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "quickjs.h"

struct OrbisScriptHost {
  JSRuntime *rt;
  JSContext *ctx;
  // The most recent rejection nothing has handled, owned here. Cleared when a
  // handler is attached late, or when it is handed to the caller by pump.
  char *pending_rejection;
};

static char *dup_cstr(const char *s) {
  if (!s) return NULL;
  size_t n = strlen(s) + 1;
  char *out = (char *)malloc(n);
  if (out) memcpy(out, s, n);
  return out;
}

// Renders a thrown or rejected value as "message\n  at ..." so the JavaScript
// stack survives the crossing. Borrows `value`; the caller still owns it.
static char *format_error_value(JSContext *ctx, JSValueConst value) {
  const char *msg = JS_ToCString(ctx, value);
  char *result = NULL;

  JSValue stack = JS_GetPropertyStr(ctx, value, "stack");
  const char *stack_str =
      JS_IsUndefined(stack) ? NULL : JS_ToCString(ctx, stack);

  if (msg && stack_str) {
    size_t n = strlen(msg) + strlen(stack_str) + 2;
    result = (char *)malloc(n);
    if (result) snprintf(result, n, "%s\n%s", msg, stack_str);
  } else {
    result = dup_cstr(msg ? msg : "unknown JavaScript error");
  }

  if (stack_str) JS_FreeCString(ctx, stack_str);
  JS_FreeValue(ctx, stack);
  if (msg) JS_FreeCString(ctx, msg);
  return result;
}

static char *format_exception(JSContext *ctx) {
  JSValue exc = JS_GetException(ctx);
  char *result = format_error_value(ctx, exc);
  JS_FreeValue(ctx, exc);
  return result;
}

// A promise rejected with nothing to catch it is not a job failure as far as
// QuickJS is concerned, so without this the throw inside a `.then` would be
// dropped on the floor. For a runtime that exists to run other people's mods,
// silently losing an async error is the worst available behaviour.
static void rejection_tracker(JSContext *ctx, JSValueConst promise,
                              JSValueConst reason, bool is_handled,
                              void *opaque) {
  (void)promise;
  OrbisScriptHost *host = (OrbisScriptHost *)opaque;
  if (!host) return;

  if (is_handled) {
    // A handler was attached after the fact; the rejection is no longer news.
    free(host->pending_rejection);
    host->pending_rejection = NULL;
    return;
  }

  // Keep the first unhandled rejection of a batch: it is the one with the
  // cause, and later ones are usually its consequences.
  if (host->pending_rejection) return;
  host->pending_rejection = format_error_value(ctx, reason);
}

OrbisScriptHost *orbis_script_new(void) {
  OrbisScriptHost *host = (OrbisScriptHost *)calloc(1, sizeof(OrbisScriptHost));
  if (!host) return NULL;

  host->rt = JS_NewRuntime();
  if (!host->rt) {
    free(host);
    return NULL;
  }

  host->ctx = JS_NewContext(host->rt);
  if (!host->ctx) {
    JS_FreeRuntime(host->rt);
    free(host);
    return NULL;
  }

  JS_SetHostPromiseRejectionTracker(host->rt, rejection_tracker, host);
  return host;
}

void orbis_script_free(OrbisScriptHost *host) {
  if (!host) return;
  free(host->pending_rejection);
  JS_FreeContext(host->ctx);
  JS_FreeRuntime(host->rt);
  free(host);
}

int orbis_script_eval(OrbisScriptHost *host, const char *src,
                      const char *filename, char **out) {
  if (out) *out = NULL;
  if (!host || !src) return 1;

  JSValue val = JS_Eval(host->ctx, src, strlen(src),
                        filename ? filename : "<eval>", JS_EVAL_TYPE_GLOBAL);

  if (JS_IsException(val)) {
    JS_FreeValue(host->ctx, val);
    if (out) *out = format_exception(host->ctx);
    return 1;
  }

  const char *s = JS_ToCString(host->ctx, val);
  if (out) *out = dup_cstr(s ? s : "undefined");
  if (s) JS_FreeCString(host->ctx, s);
  JS_FreeValue(host->ctx, val);
  return 0;
}

int orbis_script_pump(OrbisScriptHost *host, char **err_out) {
  if (err_out) *err_out = NULL;
  if (!host) return -1;

  int ran = 0;
  for (;;) {
    JSContext *pending = NULL;
    int rc = JS_ExecutePendingJob(host->rt, &pending);
    if (rc < 0) {
      if (err_out) *err_out = format_exception(pending ? pending : host->ctx);
      return -1;
    }
    if (rc == 0) break;  // queue drained
    ran++;
  }

  // Draining can settle promises, so rejections are collected after the loop
  // rather than during it.
  if (host->pending_rejection) {
    if (err_out) {
      *err_out = host->pending_rejection;
    } else {
      free(host->pending_rejection);
    }
    host->pending_rejection = NULL;
    return -1;
  }
  return ran;
}

void orbis_script_string_free(char *s) { free(s); }

// quickjs-ng exposes the version only as separate numeric macros, so the
// display string is composed here rather than read from one.
#define ORBIS_STR_(x) #x
#define ORBIS_STR(x) ORBIS_STR_(x)

const char *orbis_script_engine_version(void) {
  return ORBIS_STR(QJS_VERSION_MAJOR) "." ORBIS_STR(QJS_VERSION_MINOR) "." ORBIS_STR(
      QJS_VERSION_PATCH) QJS_VERSION_SUFFIX;
}
