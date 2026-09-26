# "TMCELL arkaly töleg" — balance top-up by phone transfer

Ported from `yaka_mine`'s `add_money_phone_page.dart`, rebuilt in Aýkitap's
own design language (bordered cards, `AppColors`, the payment module's
existing sheet/button vocabulary) rather than copied.

## How the payment actually works
Aýkitap never touches the money. TMCELL moves it between two of its own
numbers when the reader sends an SMS to the short code **0804**, whose body
is `<receiver>   <amount>`. The app only composes that SMS and hands it to
the messaging app. Nothing on the screen reports success, because the app
cannot know whether the SMS was sent — the balance is credited server-side
once the transfer lands, the same way the bank-card path waits for the bank.

## Files
- `lib/core/services/tmcell_payment_config.dart` — short code, amounts, and
  `transferSms()`. The **receiving number is a build-time value**
  (`--dart-define=TMCELL_RECEIVER_PHONE=…`), not in source control, for the
  same reason `ApiConfig.fallbackBaseUrl` isn't: it is an account number, and
  a wrong one sends readers' money to a stranger. Without it the option is
  not offered at all.
- `lib/modules/payment/tmcell_payment_screen.dart` — amount picker, the
  reader's own number, three explanation cards, an agreement checkbox, and
  the button that opens the SMS.
- `lib/modules/payment/widgets/tmcell_payment_parts.dart` — its pieces.
- `payment_method_sheet.dart` — new `PaymentMethodChoice.tmcell` row.
- `balance_top_up.dart` — routes it, on both the wallet and store paths.

## When it is offered
`_canOfferTmcell` — both conditions necessary:
1. a receiving number is configured into the build, and
2. `PurchaseModeService.isIOSStoreOnly` is off. On iOS, while the admin
   panel's "Diňe App Store tölegleri" switch is on, nothing outside App Store
   billing may be offered (guideline 3.1.1). Android always passes this.

## Still needed
- The real receiving number, and confirmation of the allowed amounts
  (currently 20/30/40/50, taken from yaka_mine).
- **Backend:** something must watch transfers arriving on that number and
  credit the user's Aýkitap balance. `yaka_mine` has a backend doing exactly
  this plus a `phone-payment-limit` endpoint (daily caps, receiver number,
  allowed amounts) that Aýkitap has no equivalent of. Until that exists the
  SMS will send but no balance will appear.
