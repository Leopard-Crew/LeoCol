/*
 * LeoCol bundle metadata probe.
 *
 * This probe reads basic bundle metadata through CoreFoundation.
 * It is a Phase 4b proof before integrating metadata into the identity resolver.
 */

#include <CoreFoundation/CoreFoundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void
leocol_print_cfstring(const char *label, CFStringRef value)
{
    char buffer[1024];

    if (label == NULL) {
        label = "value";
    }

    if (value == NULL) {
        printf("%s: -\n", label);
        return;
    }

    if (!CFStringGetCString(value,
                            buffer,
                            sizeof(buffer),
                            kCFStringEncodingUTF8)) {
        printf("%s: <unprintable>\n", label);
        return;
    }

    printf("%s: %s\n", label, buffer);
}

static CFStringRef
leocol_copy_info_string(CFBundleRef bundle, CFStringRef key)
{
    CFTypeRef value;

    if (bundle == NULL || key == NULL) {
        return NULL;
    }

    value = CFBundleGetValueForInfoDictionaryKey(bundle, key);

    if (value == NULL || CFGetTypeID(value) != CFStringGetTypeID()) {
        return NULL;
    }

    CFRetain(value);
    return (CFStringRef)value;
}

int
main(int argc, char **argv)
{
    const char *bundle_path;
    CFURLRef bundle_url;
    CFBundleRef bundle;
    CFStringRef identifier;
    CFStringRef name;
    CFStringRef short_version;
    CFStringRef bundle_version;

    if (argc != 2) {
        fprintf(stderr, "usage: leocol_bundle_metadata_probe /path/to/App.app\n");
        return 1;
    }

    bundle_path = argv[1];

    bundle_url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
                                                         (const UInt8 *)bundle_path,
                                                         strlen(bundle_path),
                                                         true);

    if (bundle_url == NULL) {
        fprintf(stderr, "leocol_bundle_metadata_probe: could not create bundle URL\n");
        return 1;
    }

    bundle = CFBundleCreate(kCFAllocatorDefault, bundle_url);
    CFRelease(bundle_url);

    if (bundle == NULL) {
        fprintf(stderr,
                "leocol_bundle_metadata_probe: could not open bundle: %s\n",
                bundle_path);
        return 1;
    }

    identifier = CFBundleGetIdentifier(bundle);
    if (identifier != NULL) {
        CFRetain(identifier);
    }

    name = leocol_copy_info_string(bundle, CFSTR("CFBundleName"));
    short_version = leocol_copy_info_string(bundle, CFSTR("CFBundleShortVersionString"));
    bundle_version = leocol_copy_info_string(bundle, CFSTR("CFBundleVersion"));

    printf("bundle_path: %s\n", bundle_path);
    leocol_print_cfstring("bundle_identifier", identifier);
    leocol_print_cfstring("bundle_name", name);
    leocol_print_cfstring("bundle_short_version", short_version);
    leocol_print_cfstring("bundle_version", bundle_version);

    if (bundle_version != NULL) {
        CFRelease(bundle_version);
    }

    if (short_version != NULL) {
        CFRelease(short_version);
    }

    if (name != NULL) {
        CFRelease(name);
    }

    if (identifier != NULL) {
        CFRelease(identifier);
    }

    CFRelease(bundle);

    return 0;
}
