part of 'send_gift_sheet.dart';

/// [_SendGiftSheetState]'s phone-check/submit logic — split out of
/// send_gift_sheet.dart to keep that file under the 200-line limit. Pure
/// mechanical move: every expression here is unchanged from before the
/// split, aside from `AccountService.instance.refresh()` switching to
/// `context.read<AccountService>()` (it's a registered
/// `ChangeNotifierProvider` in main.dart — see refactor-progress.md), which
/// needed one extra `if (!mounted) return;` guard the `.instance` call
/// didn't (a `.instance` call needs no `BuildContext`, so it never had to
/// check the widget was still around before making it).
extension _SendGiftSheetActions on _SendGiftSheetState {
  String _formatPhone(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i % 2 == 1 && i != digits.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  void _onPhoneChanged(String value) {
    final allDigits = value.replaceAll(RegExp(r'\D'), '');
    final digits = allDigits.substring(
        0, allDigits.length.clamp(0, SendGiftSheet._digitsNeeded));
    final formatted = _formatPhone(digits);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _userCheckDebounce?.cancel();
    _setState(() => _submitError = null);
    if (digits.length < SendGiftSheet._digitsNeeded) {
      _setState(() => _userCheckStatus = GiftUserCheckStatus.idle);
      return;
    }
    _setState(() => _userCheckStatus = GiftUserCheckStatus.checking);
    _userCheckDebounce = Timer(const Duration(milliseconds: 500), _checkUser);
  }

  Future<void> _checkUser() async {
    final phoneAtRequest = _apiPhone;
    try {
      final exists =
          await GiftApiService.checkUserExists(phone: phoneAtRequest);
      // The phone field may have changed while this was in flight — a
      // stale response landing after a newer request must not overwrite it.
      if (!mounted || phoneAtRequest != _apiPhone) return;
      _setState(() => _userCheckStatus =
          exists ? GiftUserCheckStatus.found : GiftUserCheckStatus.notFound);
    } on ApiException {
      if (!mounted || phoneAtRequest != _apiPhone) return;
      _setState(() => _userCheckStatus = GiftUserCheckStatus.error);
    }
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (!_canSubmit || amount == null) return;

    // Caught here rather than left to the backend's 400: the balance is
    // already on the device, and a rejected send is otherwise a round trip
    // that ends in an error the reader can't see (see [_submitError]).
    // Skipped while the balance is still unknown — null means /users/me
    // hasn't answered yet, not that the account is empty — in which case the
    // server stays the authority, as it does anyway for a balance that went
    // stale (spent on another device between this read and the send).
    final balance = context.read<AccountService>().balanceManat;
    if (balance != null && amount > balance) {
      _setState(() => _submitError = GiftStrings.insufficientBalance(balance));
      return;
    }

    _setState(() {
      _sending = true;
      _submitError = null;
    });
    try {
      await GiftApiService.sendToFriend(
          phone: _apiPhone, amount: amount.toDouble());
      // The transfer has been confirmed by the backend. Refresh before the
      // success dialog so the profile balance behind it is already accurate
      // once the user taps "Done".
      if (!mounted) return;
      await context.read<AccountService>().refresh();
      if (!mounted) return;
      await GiftSuccessDialog.show(context, amount: amount);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(() {
        _sending = false;
        _submitError = _giftErrorMessage(e);
      });
    }
  }

  /// The backend's own `message` is shown as-is for everything except the
  /// one error it words in English regardless of the reader's language:
  /// `You do not have enough balance`. There is no error *code* to match on
  /// — that message is the only signal the endpoint gives — so the match is
  /// on the text, kept loose enough to survive casing and punctuation, and
  /// falling through to the server's wording if it ever changes.
  String _giftErrorMessage(ApiException e) {
    final normalized = e.message.toLowerCase();
    if (e.statusCode == 400 && normalized.contains('enough balance')) {
      final balance = context.read<AccountService>().balanceManat;
      if (balance != null) return GiftStrings.insufficientBalance(balance);
    }
    return e.message;
  }
}
