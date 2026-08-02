# 🚀 Codemagic দিয়ে iOS App Store-এ অ্যাপ আপলোড করার গাইড (Step-by-Step)

আমরা প্রজেক্টের সমস্ত iOS ফাইল এবং কনফিগারেশন **Codemagic** ও **App Store**-এর জন্য সম্পূর্ণ রেডি করে দিয়েছি।

---

## 🛠️ আমি যে ফাইলগুলো তৈরি ও আপডেট করেছি:

1. 🆔 **Bundle ID আপডেট:** `ios/Runner.xcodeproj/project.pbxproj`-এ Bundle ID পরিবর্তিত হয়ে `com.drycleanplus.service.uk.app` হয়েছে (Android-এর সাথে সামঞ্জস্য রেখে)।
2. 🔐 **Info.plist:** App Store Export Compliance (`ITSAppUsesNonExemptEncryption`) এবং Notification BG modes যুক্ত করা হয়েছে।
3. 📜 **PrivacyInfo.xcprivacy:** Apple-এর বাধ্যতাবোধক Privacy Manifest ফাইল তৈরি করা হয়েছে (`ios/Runner/PrivacyInfo.xcprivacy`)।
4. 🔑 **Runner.entitlements:** Push Notifications capability ফাইল তৈরি করা হয়েছে (`ios/Runner/Runner.entitlements`)।
5. 📦 **ExportOptions.plist:** iOS IPA build export এর জন্য (`ios/ExportOptions.plist`) তৈরি করা হয়েছে।
6. ⚙️ **codemagic.yaml:** Codemagic-এ ১-ক্লিকে Cloud-এ iOS Build ও TestFlight/App Store-এ অটোমেটিক আপলোডের জন্য রুট ফোল্ডারে তৈরি করা হয়েছে।
7. 📄 **GoogleService-Info.plist Template:** `ios/Runner/GoogleService-Info.plist` ফাইলটির টেমপ্লেট বসানো হয়েছে।

---

## 📋 প্রথম ধাপ (Step 1): Firebase iOS Config ফাইল ডাউনলোড করুন
1. **[Firebase Console](https://console.firebase.google.com)**-এ যান।
2. আপনার **DrycleanPlus** প্রজেক্টটি ওপেন করুন।
3. **Project Settings (⚙️ icon)** -> **General**-এ যান।
4. **Your apps** সেকশনে **Add app** ক্লিক করে **iOS** নির্বাচন করুন।
5. **iOS Bundle ID**: `com.drycleanplus.service.uk.app` দিন।
6. **Register App** ক্লিক করে **`GoogleService-Info.plist`** ফাইলটি ডাউনলোড করুন।
7. ডাউনলোড করা `GoogleService-Info.plist` ফাইলটি আপনার প্রজেক্টের `ios/Runner/` ফোল্ডারে রিপ্লেস (Replace) করে দিন।

---

## 🔑 দ্বিতীয় ধাপ (Step 2): App Store Connect API Key তৈরি করুন
1. **[App Store Connect](https://appstoreconnect.apple.com)**-এ লগইন করুন।
2. **Users and Access** -> **Integrations** (বা **Keys**) ট্যাবে যান।
3. **App Store Connect API Key** তৈরি করতে **Generate API Key** (বা **+**) ক্লিক করুন।
4. Name দিন (যেমন: `Codemagic Key`), Access level দিন **Admin** বা **App Manager**।
5. **Generate** করার পর আপনি ৩টি তথ্য পাবেন:
   - **Key ID** (যেমন: `2X9R5XYZ88`)
   - **Issuer ID** (যেমন: `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
   - **Download API Key** (একটি `.p8` ফাইল প্রাইভেট কি - এটি শুধু একবারই ডাউনলোড করা যায়)।

---

## ☁️ তৃতীয় ধাপ (Step 3): Codemagic-এ প্রজেক্ট কানেক্ট করুন
1. **[Codemagic.io](https://codemagic.io)**-তে লগইন (বা সাইন আপ) করুন।
2. **Add application** ক্লিক করে আপনার **GitHub** রিওপজিটরি কানেক্ট করুন যেখানে এই Flutter প্রজেক্টটি আছে।
3. **Team Settings** -> **Developer Portal** -> **App Store Connect** সেকশনে গিয়ে আপনার ২য় ধাপে পাওয়া Apple API Key (`Issuer ID`, `Key ID`, `.p8` file) আপলোড করে কানেক্ট করুন।
4. প্রজেক্ট সেটিংসে **Code signing** এ **Enable automatic code signing** অন করুন এবং আপনার Apple Developer Account সিলেক্ট করুন।

---

## 🚀 চতুর্থ ধাপ (Step 4): Build & Publish শুরু করুন!
1. Codemagic ড্যাশবোর্ডে গিয়ে **Start new build** বাটন চাপুন।
2. Branch নির্বাচন করুন (যেমন: `main` বা `master`) এবং Workflow সিলেক্ট করুন **DrycleanPlus iOS App Store Build**।
3. **Start build** চাপুন!

✨ **ফলাফল:** Codemagic নিজের Mac মিনিতে আপনার iOS অ্যাপটি বিল্ড করে অটোমেটিক **App Store Connect / TestFlight**-এ আপলোড করে দেবে!

---

## 📱 পঞ্চম ধাপ (Step 5): App Store Connect-এ জমা দেওয়া
1. **[App Store Connect](https://appstoreconnect.apple.com)**-এ **My Apps** -> **DrycleanPlus** এ যান।
2. **Screenshots** (6.7" এবং 6.5" iPhone display), Description, Privacy Policy URL বসান।
3. **Build** সেকশনে Codemagic থেকে আপলোড হওয়া Build-টি সিলেক্ট করুন।
4. **Submit for Review** চাপুন! Apple ১-২ দিনের মধ্যে রিভিউ করে App Store-এ লাইভ করে দেবে। 🎉
