import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows a report reason selection sheet.
/// Returns the selected reason key (e.g. 'harassment') or null if dismissed.
Future<String?> showReportReasonSheet(BuildContext context) async {
  String? selected;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SheetSelect(
        items: [
          SheetItem(title: l10n.reportReasonHarassment, onTap: () => selected = 'harassment'),
          SheetItem(title: l10n.reportReasonHateSpeech, onTap: () => selected = 'hate_speech'),
          SheetItem(title: l10n.reportReasonViolence, onTap: () => selected = 'violence'),
          SheetItem(title: l10n.reportReasonSexualContent, onTap: () => selected = 'sexual_content'),
          SheetItem(title: l10n.reportReasonSpam, onTap: () => selected = 'spam'),
          SheetItem(title: l10n.reportReasonSelfHarm, onTap: () => selected = 'self_harm'),
          SheetItem(title: l10n.reportReasonImpersonation, onTap: () => selected = 'impersonation'),
          SheetItem(title: l10n.reportReasonOther, onTap: () => selected = 'other'),
        ],
      );
    },
  );
  return selected;
}
