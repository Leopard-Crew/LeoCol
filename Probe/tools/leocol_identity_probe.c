/*
 * LeoCol identity resolver probe.
 *
 * This probe resolves conservative process identities from recorded
 * process_lifecycle rows using executable paths and native CoreFoundation
 * bundle metadata where an enclosing .app bundle can be derived.
 *
 * It does not use LaunchServices, Spotlight, code signing, or live process state.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <sqlite3.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef SQLITE_TRANSIENT
#define SQLITE_TRANSIENT ((sqlite3_destructor_type)-1)
#endif

typedef struct LeoColIdentityResult {
    char bundle_path[1024];
    char bundle_identifier[256];
    char bundle_name[256];
    char bundle_version[128];
    char classification[64];
    char confidence[64];
    char notes[256];
} LeoColIdentityResult;

typedef struct LeoColIdentityContext {
    sqlite3 *db;
    int lifecycles_processed;
    int identities_inserted;
} LeoColIdentityContext;

static const char *
leocol_default_db_path(void)
{
    return "Probe/results/leocol-v1.db";
}

static int
leocol_string_starts_with(const char *text, const char *prefix)
{
    size_t prefix_len;

    if (text == NULL || prefix == NULL) {
        return 0;
    }

    prefix_len = strlen(prefix);

    return strncmp(text, prefix, prefix_len) == 0;
}

static void
leocol_copy_string(char *dst, size_t dst_size, const char *src)
{
    size_t i;

    if (dst == NULL || dst_size == 0) {
        return;
    }

    dst[0] = '\0';

    if (src == NULL) {
        return;
    }

    for (i = 0; i + 1 < dst_size && src[i] != '\0'; i++) {
        dst[i] = src[i];
    }

    dst[i] = '\0';
}

static int
leocol_copy_cfstring(char *dst, size_t dst_size, CFStringRef value)
{
    if (dst == NULL || dst_size == 0) {
        errno = EINVAL;
        return -1;
    }

    dst[0] = '\0';

    if (value == NULL) {
        return 0;
    }

    if (!CFStringGetCString(value, dst, dst_size, kCFStringEncodingUTF8)) {
        dst[0] = '\0';
        return -1;
    }

    return 0;
}

static CFStringRef
leocol_get_bundle_info_string(CFBundleRef bundle, CFStringRef key)
{
    CFTypeRef value;

    if (bundle == NULL || key == NULL) {
        return NULL;
    }

    value = CFBundleGetValueForInfoDictionaryKey(bundle, key);

    if (value == NULL || CFGetTypeID(value) != CFStringGetTypeID()) {
        return NULL;
    }

    return (CFStringRef)value;
}

static int
leocol_exec_sql(sqlite3 *db, const char *sql, const char *label)
{
    char *error_message;
    int rc;

    error_message = NULL;

    rc = sqlite3_exec(db, sql, NULL, NULL, &error_message);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_identity_probe: %s failed: %s\n",
                label,
                error_message != NULL ? error_message : sqlite3_errmsg(db));

        if (error_message != NULL) {
            sqlite3_free(error_message);
        }

        return -1;
    }

    return 0;
}

static int
leocol_bind_text_or_null(sqlite3_stmt *stmt, int index, const char *text)
{
    if (text == NULL || text[0] == '\0' || strcmp(text, "-") == 0) {
        return sqlite3_bind_null(stmt, index);
    }

    return sqlite3_bind_text(stmt, index, text, -1, SQLITE_TRANSIENT);
}

static int
leocol_create_identity_schema(sqlite3 *db)
{
    return leocol_exec_sql(db,
                           "CREATE TABLE IF NOT EXISTS process_identity ("
                           "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
                           "    lifecycle_id INTEGER NOT NULL,"
                           "    bundle_path TEXT,"
                           "    bundle_identifier TEXT,"
                           "    bundle_name TEXT,"
                           "    bundle_version TEXT,"
                           "    classification TEXT,"
                           "    confidence TEXT NOT NULL DEFAULT 'unknown',"
                           "    notes TEXT"
                           ");",
                           "process_identity schema creation");
}

static void
leocol_detect_app_bundle(const char *executable_path, LeoColIdentityResult *result)
{
    const char *marker;
    size_t bundle_len;

    if (executable_path == NULL || result == NULL) {
        return;
    }

    marker = strstr(executable_path, ".app/Contents/MacOS/");

    if (marker == NULL) {
        return;
    }

    bundle_len = (size_t)(marker - executable_path) + 4;

    if (bundle_len >= sizeof(result->bundle_path)) {
        return;
    }

    memcpy(result->bundle_path, executable_path, bundle_len);
    result->bundle_path[bundle_len] = '\0';

    leocol_copy_string(result->confidence,
                       sizeof(result->confidence),
                       "path-app-contained");
}

static void
leocol_classify_path(const char *executable_path, LeoColIdentityResult *result)
{
    if (result == NULL) {
        return;
    }

    leocol_copy_string(result->classification,
                       sizeof(result->classification),
                       "unknown");
    leocol_copy_string(result->confidence,
                       sizeof(result->confidence),
                       "unknown");
    leocol_copy_string(result->notes,
                       sizeof(result->notes),
                       "No executable path classification available.");

    if (executable_path == NULL || executable_path[0] == '\0') {
        return;
    }

    leocol_copy_string(result->notes,
                       sizeof(result->notes),
                       "Classified by executable path prefix.");

    if (leocol_string_starts_with(executable_path, "/System/Library/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "Apple system component");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-prefix");
        return;
    }

    if (leocol_string_starts_with(executable_path, "/Developer/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "developer tool");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-prefix");
        return;
    }

    if (leocol_string_starts_with(executable_path, "/opt/local/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "MacPorts tool");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-prefix");
        return;
    }

    if (leocol_string_starts_with(executable_path, "/bin/") ||
        leocol_string_starts_with(executable_path, "/sbin/") ||
        leocol_string_starts_with(executable_path, "/usr/bin/") ||
        leocol_string_starts_with(executable_path, "/usr/sbin/") ||
        leocol_string_starts_with(executable_path, "/usr/libexec/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "command-line tool");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-cli");
        return;
    }

    if (leocol_string_starts_with(executable_path, "/Applications/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "user application");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-prefix");
        return;
    }

    if (leocol_string_starts_with(executable_path, "/Users/")) {
        leocol_copy_string(result->classification,
                           sizeof(result->classification),
                           "user application");
        leocol_copy_string(result->confidence,
                           sizeof(result->confidence),
                           "path-prefix");
        return;
    }
}

static void
leocol_enrich_bundle_metadata(LeoColIdentityResult *result)
{
    CFURLRef bundle_url;
    CFBundleRef bundle;
    CFStringRef identifier;
    CFStringRef name;
    CFStringRef short_version;
    CFStringRef bundle_version;

    if (result == NULL || result->bundle_path[0] == '\0') {
        return;
    }

    bundle_url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
                                                         (const UInt8 *)result->bundle_path,
                                                         strlen(result->bundle_path),
                                                         true);

    if (bundle_url == NULL) {
        return;
    }

    bundle = CFBundleCreate(kCFAllocatorDefault, bundle_url);
    CFRelease(bundle_url);

    if (bundle == NULL) {
        return;
    }

    identifier = CFBundleGetIdentifier(bundle);
    name = leocol_get_bundle_info_string(bundle, CFSTR("CFBundleName"));
    short_version = leocol_get_bundle_info_string(bundle, CFSTR("CFBundleShortVersionString"));
    bundle_version = leocol_get_bundle_info_string(bundle, CFSTR("CFBundleVersion"));

    leocol_copy_cfstring(result->bundle_identifier,
                         sizeof(result->bundle_identifier),
                         identifier);
    leocol_copy_cfstring(result->bundle_name,
                         sizeof(result->bundle_name),
                         name);

    if (short_version != NULL) {
        leocol_copy_cfstring(result->bundle_version,
                             sizeof(result->bundle_version),
                             short_version);
    } else {
        leocol_copy_cfstring(result->bundle_version,
                             sizeof(result->bundle_version),
                             bundle_version);
    }

    CFRelease(bundle);
}

static void
leocol_refine_classification_from_bundle_metadata(LeoColIdentityResult *result)
{
    if (result == NULL) {
        return;
    }

    if (strcmp(result->classification, "user application") != 0) {
        return;
    }

    if (!leocol_string_starts_with(result->bundle_identifier, "com.apple.")) {
        return;
    }

    leocol_copy_string(result->classification,
                       sizeof(result->classification),
                       "Apple application");

    leocol_copy_string(result->confidence,
                       sizeof(result->confidence),
                       "bundle-identifier");

    leocol_copy_string(result->notes,
                       sizeof(result->notes),
                       "Classified as Apple application by com.apple bundle identifier.");
}

static void
leocol_resolve_identity(const char *executable_path, LeoColIdentityResult *result)
{
    if (result == NULL) {
        return;
    }

    memset(result, 0, sizeof(*result));

    leocol_classify_path(executable_path, result);
    leocol_detect_app_bundle(executable_path, result);

    if (result->bundle_path[0] != '\0') {
        leocol_enrich_bundle_metadata(result);

        if (result->bundle_identifier[0] != '\0' ||
            result->bundle_name[0] != '\0' ||
            result->bundle_version[0] != '\0') {
            leocol_copy_string(result->notes,
                               sizeof(result->notes),
                               "Derived containing .app bundle and CoreFoundation metadata from executable path.");
        } else {
            leocol_copy_string(result->notes,
                               sizeof(result->notes),
                               "Derived containing .app bundle from executable path.");
        }

        leocol_refine_classification_from_bundle_metadata(result);
    }
}

static int
leocol_insert_identity(sqlite3 *db,
                       sqlite_int64 lifecycle_id,
                       const LeoColIdentityResult *identity)
{
    sqlite3_stmt *stmt;
    int rc;

    if (db == NULL || identity == NULL) {
        errno = EINVAL;
        return -1;
    }

    stmt = NULL;

    rc = sqlite3_prepare_v2(db,
                            "INSERT INTO process_identity ("
                            "    lifecycle_id,"
                            "    bundle_path,"
                            "    bundle_identifier,"
                            "    bundle_name,"
                            "    bundle_version,"
                            "    classification,"
                            "    confidence,"
                            "    notes"
                            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_identity_probe: prepare identity insert failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_int64(stmt, 1, lifecycle_id);

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 2, identity->bundle_path);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 3, identity->bundle_identifier);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 4, identity->bundle_name);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 5, identity->bundle_version);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 6, identity->classification);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 7, identity->confidence);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 8, identity->notes);
    }

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_identity_probe: bind identity insert failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_identity_probe: identity insert failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);
    return 0;
}

static int
leocol_rebuild_identities(LeoColIdentityContext *context)
{
    sqlite3_stmt *stmt;
    int rc;

    if (context == NULL || context->db == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (leocol_create_identity_schema(context->db) != 0) {
        return -1;
    }

    if (leocol_exec_sql(context->db, "BEGIN TRANSACTION;", "begin transaction") != 0) {
        return -1;
    }

    if (leocol_exec_sql(context->db, "DELETE FROM process_identity;", "clear process_identity") != 0) {
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    stmt = NULL;

    rc = sqlite3_prepare_v2(context->db,
                            "SELECT id, executable_path "
                            "FROM process_lifecycle "
                            "ORDER BY id;",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_identity_probe: prepare lifecycle scan failed: %s\n",
                sqlite3_errmsg(context->db));
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        sqlite_int64 lifecycle_id;
        const char *executable_path;
        LeoColIdentityResult identity;

        lifecycle_id = sqlite3_column_int64(stmt, 0);
        executable_path = (const char *)sqlite3_column_text(stmt, 1);

        leocol_resolve_identity(executable_path, &identity);

        if (leocol_insert_identity(context->db, lifecycle_id, &identity) != 0) {
            sqlite3_finalize(stmt);
            leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
            return -1;
        }

        context->lifecycles_processed++;
        context->identities_inserted++;
    }

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_identity_probe: lifecycle scan failed: %s\n",
                sqlite3_errmsg(context->db));
        sqlite3_finalize(stmt);
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    sqlite3_finalize(stmt);

    if (leocol_exec_sql(context->db, "COMMIT;", "commit") != 0) {
        return -1;
    }

    return 0;
}

int
main(int argc, char **argv)
{
    const char *db_path;
    LeoColIdentityContext context;

    db_path = leocol_default_db_path();

    if (argc > 1) {
        db_path = argv[1];
    }

    memset(&context, 0, sizeof(context));

    if (sqlite3_open(db_path, &context.db) != SQLITE_OK) {
        fprintf(stderr,
                "leocol_identity_probe: could not open database %s: %s\n",
                db_path,
                context.db != NULL ? sqlite3_errmsg(context.db) : "unknown error");

        if (context.db != NULL) {
            sqlite3_close(context.db);
        }

        return 1;
    }

    if (leocol_rebuild_identities(&context) != 0) {
        sqlite3_close(context.db);
        return 1;
    }

    sqlite3_close(context.db);

    printf("leocol_identity_probe: processed %d lifecycles, inserted %d identities\n",
           context.lifecycles_processed,
           context.identities_inserted);

    return 0;
}
