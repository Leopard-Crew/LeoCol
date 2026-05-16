# LeoCol Collector Model

## Purpose

The collector observes process lifecycle and lightweight resource facts.

It does not interpret aggressively.

It records what was seen, when it was seen, and how confident the observation is.

## Observation types

### Process seen

A process was present in a sample.

Fields:

- timestamp,
- pid,
- ppid,
- uid,
- process name,
- executable path if available,
- command line if safely available,
- CPU sample if available,
- memory sample if available.

### Process first seen

A process appears in the journal that was not present in the previous sample.

This is an observation, not a guaranteed exact start event.

### Process last seen

A process disappears between two samples.

This is an observation, not a guaranteed exact exit event.

### Identity resolved

A process was mapped to a likely application, bundle, helper, system component, or unknown origin.

### Resource sample

CPU and memory values were sampled for trend purposes.

LeoCol should not pretend to be a high-precision profiler.

## Sampling model

V1 should use polling.

Polling is acceptable because LeoCol is a historical collector, not a real-time enforcement system.

A reasonable first interval is 5 seconds.

The interval should later become configurable.

## Confidence

LeoCol should distinguish facts from inferences.

Examples:

```text
fact:
  pid 123 was observed at 2026-05-10 15:10:00

inference:
  pid 123 probably belongs to Safari.app

unknown:
  no bundle relationship found
````

## Classification

Initial classifications:

- Apple system component,
    
- Apple application,
    
- user application,
    
- helper tool,
    
- command-line tool,
    
- MacPorts tool,
    
- developer build,
    
- unknown.
    

Classification must remain descriptive, not judgmental.


