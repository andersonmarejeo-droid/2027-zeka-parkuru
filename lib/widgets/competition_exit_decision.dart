import 'package:flutter/material.dart';

enum CompetitionExitDecision { retry, skip, leave }

Future<CompetitionExitDecision> showCompetitionExitDecision(
  BuildContext context, {
  required String flowName,
  required String gameName,
}) async {
  final CompetitionExitDecision?
  decision = await showModalBottomSheet<CompetitionExitDecision>(
    context: context,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return PopScope(
        canPop: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF18345F), Color(0xFF111E3B)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF4C79AE)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x2637E6B5),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(11),
                          child: Icon(
                            Icons.route_rounded,
                            color: Color(0xFF37E6B5),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              flowName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7DEFD1),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TAMAMLANMAYAN B\u00d6L\u00dcM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$gameName tamamlanmad\u0131. Parkurdaki yerin '
                    'korunuyor. Nas\u0131l devam etmek istersin?',
                    style: const TextStyle(
                      color: Color(0xFFD8E5F4),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      CompetitionExitDecision.retry,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF26DFA8),
                      foregroundColor: const Color(0xFF07192B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'TEKRAR DENE',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      CompetitionExitDecision.skip,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: const Color(0xFFFFD34E),
                      side: const BorderSide(color: Color(0xFFFFD34E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text(
                      'B\u00d6L\u00dcM\u00dc GE\u00c7',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 7, 10, 2),
                    child: Text(
                      'Bu b\u00f6l\u00fcm 0 puanla kaydedilir ve s\u0131radaki '
                      'oyun a\u00e7\u0131l\u0131r.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9DB0C8), fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      CompetitionExitDecision.leave,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: const Color(0xFFB8C7DA),
                    ),
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text(
                      'PARKURDAN \u00c7IK',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  return decision ?? CompetitionExitDecision.leave;
}
