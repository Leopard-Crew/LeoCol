# LeoCol Runtime Smoke Test

## Purpose

A successful Xcode build is not sufficient for LeoCol UI changes.

Objective-C selector issues can compile successfully and still fail at runtime.

## Required smoke test

After Cocoa UI changes, run LeoCol directly from Terminal:

```text
App/build/Debug/LeoCol.app/Contents/MacOS/LeoCol
````

## Expected result

The app must start without runtime exceptions.

The main window must appear.

The following UI areas must be checked:

- main process table,
    
- native toolbar,
    
- search field,
    
- Reload,
    
- Evidence / Belege panel,
    
- About panel,
    
- process detail inspector,
    
- bottom status line.
    

## Failure patterns

Watch for messages such as:

```text
unrecognized selector sent to instance
NSInvalidArgumentException
Exception
```

## Rule

Do not tag a UI polish release only because the build succeeded.

Tag only after the app has launched and the changed UI path has been exercised.  

