# بناء ونشر اللعبة على App Store (خطوة بخطوة)

## لماذا هذا الدليل مختلف عن دليل أندرويد؟

بناء وتوقيع تطبيقات iOS يتطلب **Xcode**، ولا يعمل Xcode إلا على macOS —
هذه قاعدة تفرضها Apple نفسها ولا علاقة لها بأي أداة نستخدمها. أنا أعمل من
خادم Linux، فلا أستطيع تنفيذ هذه الخطوة نيابة عنك مباشرة. عندك خياران:

## الخيار أ (الأسهل بلا Mac): خدمة Codemagic

Codemagic خدمة بناء سحابية متخصصة في تطبيقات Flutter، توفر أجهزة Mac
افتراضية وتتولى عملية التوقيع تلقائيًا، ولها خطة مجانية تكفي هذا المشروع.

1. اذهب إلى https://codemagic.io وسجّل دخول بحساب GitHub.
2. اربط مستودع المشروع (`elitesmile/Hadi`).
3. عند أول إعداد، اختر **Flutter App** كنوع المشروع.
4. من تبويب **Distribution → iOS code signing**، اختر **Automatic** واربط
   حساب Apple Developer الخاص بك (يطلب منك تسجيل الدخول بـ Apple ID أو رفع
   App Store Connect API Key من https://appstoreconnect.apple.com/access/api).
5. حدد Bundle Identifier: `com.elitesmile.thakirat_albilat` (يجب تسجيله
   أولًا في https://developer.apple.com/account/resources/identifiers/list
   كـ App ID جديد بنفس الاسم).
6. في **Distribution → Publishing → App Store Connect**، فعّل **Submit to
   TestFlight** (أو App Store مباشرة).
7. ابدأ البناء (Start new build). عند النجاح، سترفع Codemagic النسخة
   الموقّعة تلقائيًا إلى App Store Connect.

## الخيار ب: تملك أو تستأجر جهاز Mac

إن كان لديك ماك (أو جهاز مستأجر عبر خدمة مثل MacinCloud):

1. ثبّت Xcode من App Store على الماك.
2. ثبّت Flutter: https://docs.flutter.dev/get-started/install/macos
3. استنسخ المستودع: `git clone https://github.com/elitesmile/Hadi.git`
4. نفّذ: `flutter pub get` ثم `open ios/Runner.xcworkspace`
5. في Xcode: اختر Target **Runner** → تبويب **Signing & Capabilities**:
   - فعّل **Automatically manage signing**
   - اختر **Team** (حسابك في Apple Developer)
   - سيولّد Xcode تلقائيًا الشهادات وملف التوقيع (Provisioning Profile)
6. من القائمة العلوية اختر جهاز **Any iOS Device (arm64)**.
7. من القائمة: **Product → Archive** (يستغرق بضع دقائق).
8. بعد الانتهاء تفتح نافذة **Organizer** تلقائيًا → اضغط **Distribute App**
   → **App Store Connect** → **Upload**.

بعد هذه الخطوة (بأي من الخيارين)، ستظهر النسخة تلقائيًا في App Store Connect
خلال دقائق إلى نصف ساعة (معالجة Apple للنسخة).

## الخطوة التالية: إنشاء سجل التطبيق في App Store Connect

1. اذهب إلى https://appstoreconnect.apple.com → **My Apps → +** → **New App**
2. **الاسم**: ذاكرة البلاطات
3. **اللغة الأساسية**: العربية
4. **Bundle ID**: اختر `com.elitesmile.thakirat_albilat` (الذي سجّلته سابقًا)
5. **SKU**: أي معرّف داخلي فريد، مثلاً `thakirat-albilat-001`

## بطاقة المتجر (App Information + Store Listing)

- **الفئة (Category)**: Games → Puzzle
- **الوصف**: نفس النص المقترح في `docs/PUBLISHING_ANDROID.md`
- **الكلمات المفتاحية (Keywords)**: ذاكرة, لعبة, ألغاز, تركيز, بلاطات, matching, memory, puzzle
- **لقطات الشاشة المطلوبة**: مقاس 6.7 بوصة (iPhone 15 Pro Max) ومقاس 6.5
  بوصة إلزاميان على الأقل. يمكن التقاطها من محاكي iOS Simulator (داخل
  Xcode: Window → Devices and Simulators) أو من جهاز حقيقي.
- **سياسة الخصوصية (Privacy Policy URL)**: إلزامية حتى لو لم يجمع التطبيق
  أي بيانات. الرابط الجاهز:
  **https://claude.ai/code/artifact/d0843028-1373-4a9e-a29a-a1147313d9b2**
- **App Privacy (قسم "Privacy" في App Store Connect)**: أجب بأن التطبيق
  **لا يجمع أي بيانات (Data Not Collected)** — صحيح لأن اللعبة تعمل بالكامل
  دون اتصال إنترنت وتخزّن أفضل نتيجة محليًا فقط.
- **Age Rating**: أكمل الاستبيان، ستحصل على تصنيف 4+ لأنها لعبة عائلية بسيطة.
- **التسعير**: مجاني (Free) للبداية.

## الإرسال للمراجعة

1. بعد رفع البناء (Build) واختياره في صفحة الإصدار (Version)، تأكد أن كل
   الحقول الإلزامية معبأة (تظهر علامة ✅ خضراء).
2. اضغط **Add for Review** ثم **Submit to App Review**.
3. مراجعة Apple عادة تستغرق من 24 إلى 48 ساعة لتطبيق أول بسيط كهذا.
4. إن تم الرفض، ستصلك رسالة توضّح السبب بالتفصيل من فريق المراجعة —
   شاركني نصها وسأساعدك في إصلاح المشكلة والرفع مجددًا.

## تجربة قبل النشر عبر TestFlight (موصى به)

بدلًا من الإرسال مباشرة لـ App Store، يمكنك دعوة نفسك أو أصدقاء لتجربة
اللعبة أولًا عبر TestFlight (نفس نسخة البناء المرفوعة، بدون الحاجة لمراجعة
Apple الكاملة) — من App Store Connect → **TestFlight** → أضف مختبرين
بالبريد الإلكتروني.
