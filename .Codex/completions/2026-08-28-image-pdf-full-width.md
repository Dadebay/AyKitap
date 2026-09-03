# Image PDF full-width layout

## Problem

Scanned PDF pages opened successfully but retained large gutter bars on both
sides. Image-only books defaulted to zero page-edge crop, and pdfrx retained
its default page margin in continuous mode.

## Change

- An image-only PDF without a per-book preference starts at the widest safe
  margin crop (12% per side).
- A per-book margin choice remains authoritative.
- Continuous-scroll mode uses a zero pdfrx page margin; paged mode keeps its
  normal separation.

## Verification

- Focused PDF opener, margin-crop, and lifecycle tests passed (10 tests).
- Targeted `flutter analyze` completed with no issues.
- No APK or device build was run.

