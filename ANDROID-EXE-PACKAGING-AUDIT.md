# Sofson Android + Windows Cloud Packaging Audit

## Runtime architecture
- Android Capacitor shell loads `https://sofson.in`.
- Windows Electron shell loads `https://sofson.in`.
- Native Android Bluetooth SPP printer remains in `SofsonPrinterPlugin`.
- Windows print bridge remains under `scripts/print-bridge`.
- No Next.js server, Node.js runtime, `.next/standalone`, or Supabase service-role key is packaged into Android.

## Customer QR
Customer/store QR links remain domain-based and should point to the configured Sofson cloud routes (for example `/store`).

## Role flows
Staff and retailer authentication/routes remain part of the existing Sofson cloud application. Their route-specific CSS modules are preserved; they are not deduplicated merely because filenames/import patterns may look similar.

## Build requirement
Run `npm run build` successfully before `npm run android:prepare` and Gradle. A Gradle success after a failed Next build is not considered a valid application build.
