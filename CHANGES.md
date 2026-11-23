# DrycleanPlus — Blue redesign + Postcoder location + Pay now / Pay later

## How to apply
1. Copy everything in this zip over your project (same folder structure). Nothing else is touched
   (your keystore / key.properties / google-services are NOT included).
2. `flutter pub get`   (adds `geolocator`)
3. Run. Optional build-time keys (recommended instead of hard-coding):
   `flutter run --dart-define=POSTCODER_API_KEY=... --dart-define=SUMUP_PAY_URL=https://pay.sumup.com/b2c/XXXX`

> NOTE: this was written without a Flutter SDK available, so it has not been compiled/run.
> Run `flutter analyze` first and send me any errors.

## What changed
### Design system (whole app turns blue)
- `config/theme.dart` — new blue tokens, glass cards, soft shadows, rounded inputs/buttons. Old constant
  names kept (gold → warm amber accent, goldBorder → soft white outline) so un-rewritten screens restyle automatically.
- `widgets/app_ui.dart` — shared kit: AppBackground, AppScaffold (keyboard-aware bottom bar), AppButton,
  GlassCard, SurfaceCard, StepProgress, PriceRow, AppTextField, smoothRoute.
- Rewritten screens: onboarding, home, bottom navigation, address selection, add address,
  order summary, payment options (new), payment, booking confirmation.
- Restyled via theme/patch: time slots, contact info, and every other screen.

### Order flow
- **Instruction box + NEXT**: bottom bar now rides above the keyboard (never hidden). Instruction field no
  longer writes to Firestore on every keystroke. Editing from order summary now pops back (no duplicate page).
- **Location**: add-address screen auto-reads GPS → Postcoder `reversegeo` (house-level) → falls back to
  `rgeo` (street) → user taps their address; also postcode search (UK / Ireland) and manual entry.
  Needs: `geolocator`, Android + iOS location permission (added).
  Postcoder `reversegeo` requires AddressBase/Eircode access on your API key.
- **Tax removed** everywhere (model, provider, order summary, orders list, track order).
  Total = items − discount + service fee (£2.99) + delivery fee (£0).
- **Order summary → PAY NOW £X → Payment page** with two options:
  - *Pay now* → SumUp link opens in-app (`config/payment_config.dart`).
  - *Pay later* → Cash on delivery: order placed immediately, `paymentMethod: cod`, `paymentStatus: pay_on_delivery`.
  - Prepaid packs: Pay later is disabled.

### Bugs fixed
- Orders list / track order added service fee + tax a second time on top of an already-final total.
- Payment screen JS used an invalid selector so success was never detected; "Mark payment as completed"
  created an order with no check. Now: page-text/URL detection + confirm dialog, saved as `paid_unverified`.
- Postcoder client disabled SSL certificate checks (`badCertificateCallback = true`) — removed.
- Footer stayed visible on booking screens, leaving a blank gap above the keyboard — now hidden there.
- Double order creation guard in `createOrder`.

## Step 1 (payment gating)
- `screens/booking/payment_screen.dart`: **MARK PAYMENT AS COMPLETED is locked** (grey, lock icon) until the
  SumUp page shows the payment went through (success URL or success text, checked every second).
  A "Payment detected" chip + haptic + the button unlock when it happens.
- Leaving the page after payment was detected asks for confirmation (otherwise the order would be lost).
- Escape hatch: if detection fails, "Paid, but still locked?" appears after 90s (confirm dialog), and the order is
  saved as `paid_manual_check` so staff verify it first. Turn it off with
  `PaymentConfig.allowManualFallback = false` in `config/payment_config.dart`.
- Status values: `paid_unverified` (detected), `paid_manual_check` (fallback), `pay_on_delivery` (COD).

## Step 2 (service overview page)
- `screens/service_overview_screen.dart` redesigned (all booking logic kept): pill service selector, glass hero
  with big icon + "From £x", search box, category chips, item cards with animated + / stepper (selected = highlighted),
  prepaid packs as white cards with OFF badges, dark-blue bottom bar with item-count badge, estimated price,
  expandable selected-items list and SCHEDULE A COLLECTION button.
- Fixed: the quantity badge printed a bare "x" without the number; setState/async guards in the prepaid loader.

## Step 3 (orders)
- `utils/order_status.dart` (new): one place for status labels/colours/steps; 'completed' = 'delivered'.
- `screens/orders_screen.dart`: segmented Active/Completed tabs with counts, order cards with status chip, 4-step
  progress, payment chip (Pay on delivery / Paid online), "To pay on delivery" total, skeleton + friendly empty state.
- `screens/track_order_screen.dart`: status hero, live timeline with pulsing current step, collection/delivery +
  address, items, payment card (breakdown only when it adds up, so old orders that included tax stay correct).
- `screens/past_orders_screen.dart`: same Firestore logic, new cards (item chips, payment method, total).
- Fixed: Track order never marked 'completed' orders as delivered; Orders screen had an artificial 1s delay.

## Colour policy (pure blue)
- Removed the amber/yellow accent everywhere. Tokens in `config/theme.dart`: `gold` is now white, `goldLight` ice blue,
  `goldDark` soft sky blue, new `sky` cyan-blue. Primary buttons are white → ice-blue with deep-blue text.
- Order status chips use blue shades; only success (delivered / paid / discount) is green and errors are red.
- Hard-coded yellow / gold / purple / green / pink colours in the other screens (prices, guest prices, membership,
  offer cards, service colours, loader) were swapped for blues.

## Step 4 (More + Account)
- `screens/more_screen.dart`: profile card, grouped menu (Orders / Support / Legal) with icon badges and subtitles.
- `screens/account_screen.dart`: profile header with initials, address / contact / country cards, themed dialogs.
- Fixed: "Log out" only cleared local data and "Delete account" never deleted anything. Now both sign out of Firebase;
  delete removes the Firebase user first and only clears local data if that succeeds
  (shows "log in again, then delete" when Firebase asks for a recent login).
  NOTE: orders/addresses stored in Firestore are NOT deleted — that needs a Cloud Function.

## Onboarding + loader polish
- `screens/onboarding_screen.dart`: staggered entrance (logo → hero → text → sheet), pulsing rings around the washer
  emblem, gradient headline, rising soap bubbles, drag-handle sign-in sheet. Buttons are now premium: icon bubble,
  label, arrow, press-down animation + haptic, coloured shadow, loading state
  (Apple = black gradient, Google = white with coloured G, Guest = blue gradient). The hero scales down on short phones.
- `widgets/dryclean_loader.dart`: new signature loader — spinning washer ring, the DrycleanPlus logo is "signed" left→right,
  hand-drawn swoosh underline, sparkles, cycling status messages, loop dots, rising bubbles. Pure blue/white.
  New `autoDismiss` flag (default true = old behaviour); log out / delete account use `autoDismiss: false`
  with a minimum 1.4s so a slow network can no longer close the loader and then pop the wrong page.
- `widgets/bubble_field.dart` (new): shared animated bubble background.

## Sliders (animated, professional)
- `widgets/app_sliders.dart` (new)
  - `ChipSlider`: pill slider — items slide in one after another, the selected pill glides to the centre,
    soft edge fade, press-down bounce, haptic tick.
  - `CardCarousel`: snapping PageView — centre card full size, neighbours shrink + fade, optional auto-play that
    pauses while you touch it, animated dots (the active dot fills like a progress bar), tap a dot to jump.
- Used in: service overview (service pills, category chips, prepaid packs carousel), guest service overview
  (service pills, category chips), prepaid packs screen (both pack sliders), and a new **Offers for you**
  auto-playing promo slider on Home (prepaid savings / skip the service fee / how it works) with floating icons.

## Remaining pages (batch)
- `widgets/service_price_card.dart` (new) + `screens/prices_screen.dart` + `screens/guest_price_screen.dart`:
  glass service cards (icon, title, description, tags) with a white price footer, staggered entrance, press bounce.
- `screens/membership_screen.dart`: animated hero, benefit cards, animated plan cards (Monthly / Annual BEST VALUE),
  sticky "CALL TO SUBSCRIBE" with the selected plan summary.
- `widgets/offer_card.dart` + `screens/offers_screen.dart`: blue coupon tickets with notches, discount seal, shine,
  promo-code box, used / expired / ending-soon states, new promo dialog.
- `screens/faq_screen.dart`: search, category slider, accordion answers, "Still need help?" email/call card,
  animated location page. `screens/terms_conditions_screen.dart` + `screens/privacy_policy_screen.dart`:
  numbered animated section cards (text unchanged). `widgets/legal_section.dart` (new).
- `screens/prepaid_packs_screen.dart`: new header, animated Shop / My Packs switch, progress-ring pack cards.
- Footer is hidden while the keyboard is open.
- Not touched on purpose: `settings_screen.dart` and `booking/service_items_screen.dart` are not reachable from
  anywhere in the app (and Settings has dummy toggles) — recommend deleting them.
