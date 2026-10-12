# Splash connection-check duration

- Increased the normal-motion minimum splash/connection-check duration from 750 milliseconds to 2 seconds.
- Startup work still runs in parallel, so the change adds no extra delay when the real connection or preferences check already takes longer than 2 seconds.
- Preserved the existing reduced-motion behavior.
- Updated and ran the focused SplashScreen tests.
