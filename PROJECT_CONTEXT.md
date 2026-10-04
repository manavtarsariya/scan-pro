# PROJECT CONTEXT: ScanPro (Flutter). Read fully before every task.

## About me
- MERN developer, NEW to Flutter. Explain in simple Hinglish (Gujarati-English mix, Roman script). Code and technical terms in English.
- Use real-life examples. Avoid heavy jargon (repository pattern, layers, migration) unless I ask.
- Goal: long-term income from apps through real effort. No hype, be honest about risks.

## App
"ScanPro": all-in-one Document Scanner + PDF Toolkit + AI Document Assistant. Android first (Flutter), iOS later. No login, no backend, works offline.
Target: India + global (US, UK, Middle East). App language English first; later Hindi, Gujarati, Arabic, Spanish, French, Portuguese, Indonesian.
Later (App 2): Health and Fitness app with Indian food tracking. Do NOT work on it now.

## Features (no compromise, build in phases)
- V1: camera scan with edge detection, crop, filters (Original, Magic Color, B&W, Grayscale, Lighten, Sharpen), multi-page, gallery import, Image to PDF, Merge, Split, Compress, Organize pages, Lock/Unlock, PDF to Image/Word, My Files (folders, search, rename, share, delete, favorites), file preview, Settings, onboarding, permission primer, paywall, daily free limit, rewarded ad unlock, banner ads.
- V2 (AI, premium): OCR (ML Kit on-device), Summarize, Chat with PDF, Study Notes/Flashcards/Quiz, Translate, Handwriting to text.
- V3: eSign, watermark/page numbers, QR/Barcode, ID card scan (front+back on one A4), Drive backup, widgets, dark mode, multi-language UI.

## Monetization
Onboarding then paywall. Weekly / Monthly / Yearly (Yearly pre-selected, BEST VALUE, 3-day trial). Example: Rs 79/week, Rs 249/month, Rs 999/year.
Free: daily scan limit, watermark, ads. Premium: unlimited, no ads, no watermark, AI. Rewarded ad = 1 extra export. Core scanning never fully blocked.

## Technical decisions (do not change without telling me why)
- NO server, NO database, NO login in V1.
- SharedPreferences: settings, premium cache, daily scan counter, onboarding flag.
- Files: save in app folder via path_provider. My Files list = read the folder (Directory.listSync). No Hive, no repository pattern in V1.
- Subscriptions: RevenueCat (purchases_flutter). Ads: AdMob. Firebase: analytics + crashlytics.
- Scanning: google_mlkit_document_scanner. PDF: pdf / pdfx (add syncfusion only if needed, check license). OCR: google_mlkit_text_recognition.
- AI (V2) later via tiny serverless function so API keys are never in the app.
- Known weakness: local free-limit can be bypassed by clearing data. Acceptable for now.

## Design
- Designs are in Google Stitch (use the Stitch MCP to fetch screens, colors and layout; do not guess the UI).
- Theme: Deep rich EMERALD (#064E3B).
  Primary #064E3B, pressed #04382A, light accent #059669, soft tint #E8F5EE, gradient #064E3B to #0E7057, background #F8FAFC, surface #FFFFFF, border #E2E8F0, text #0F172A, secondary text #475569, text on primary #FFFFFF, links #047857.
  Premium: gold gradient #FFB800 to #FF7A00. AI: violet #7C4DFF. Dark: bg #0F1A15, surface #18261F.
- Font Plus Jakarta Sans. Cards 20px radius, CTA 56px tall, bottom nav 4 tabs (Home, Tools, Files, Settings) + big circular center Scan button.
- Put all colors, text styles and spacing in ONE theme file. Never hardcode colors inside screens.

## HOW YOU MUST WORK (important)
1. Before coding, give a SHORT plan (max 6 lines) and wait for my "go" if the task touches more than 3 files.
2. One feature at a time. Do not build other screens or features I did not ask for.
3. Add a package only when the current task needs it. Tell me the package name and why.
4. Keep the code simple and beginner-readable: small widgets, clear names, short comments. No clever tricks, no unnecessary abstractions.
5. After changes: run `flutter analyze`, fix errors, and tell me how to test in the emulator (what to tap, what I should see).
6. Android permissions and platform config (AndroidManifest, gradle): tell me exactly what you changed and why.
7. After each working feature, suggest a git commit message. Never delete or rewrite existing working files without asking.
8. At the end of each task, explain in simple Hinglish: which files you made, what each does, and 1 thing I should learn from it.
9. If my request conflicts with this file or with good practice, say so briefly, then follow my decision.
10. If something is uncertain (package API changed, platform issue), say you are unsure instead of guessing.

## Build order
1 Theme + bottom nav + empty screens -> 2 Onboarding, permission, paywall (UI only) -> 3 Home + Tools UI -> 4 Scan flow (camera, crop, filter, save PDF) [DONE] -> 5 My Files (File Manager, Folders, PDF preview) [DONE] -> 6 Core PDF Tools (Image to PDF, Merge, Split, Compress) [DONE] -> 7 Advanced PDF Utilities (Lock/Unlock, Watermark, eSign, PDF to Image, Organize) [DONE] -> 8 Smart Scanners (ID Card 2-Side, QR/Barcode) [DONE] -> 9 Settings & Preferences [DONE] -> 10 Dynamic Ads & Remote Config + RevenueCat.
Current step: 9 [DONE] (Next: Step 10 - Remote Config Dynamic Ads & RevenueCat Subscriptions)