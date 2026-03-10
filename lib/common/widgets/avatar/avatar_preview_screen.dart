import 'package:bemyday/common/widgets/avatar/avatar_divided_circle.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

/// AvatarDividedCircle 프리뷰 화면.
/// 실행: main.dart의 home을 AvatarPreviewScreen()으로 임시 교체.
class AvatarPreviewScreen extends StatelessWidget {
  const AvatarPreviewScreen({super.key});

  static const _names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];

  List<({String? avatarUrl, String nickname})> _mock(int count) {
    return List.generate(
      count,
      (i) => (avatarUrl: null, nickname: _names[i % _names.length]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDarkMode(context)
        ? CustomColors.borderDark
        : CustomColors.borderLight;
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar Preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _section('1 member', _mock(1), 80, borderColor),
            _section('2 members', _mock(2), 80, borderColor),
            _section('3 members', _mock(3), 80, borderColor),
            _section('4 members', _mock(4), 80, borderColor),
            _section('5 members (3 + "+2")', _mock(5), 80, borderColor),
            _section('7 members (3 + "+4")', _mock(7), 80, borderColor),
            const Divider(height: 40),
            const Text('Size comparison',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sizeDemo('40px', _mock(3), 40, borderColor),
                _sizeDemo('60px', _mock(3), 60, borderColor),
                _sizeDemo('80px', _mock(3), 80, borderColor),
                _sizeDemo('120px', _mock(3), 120, borderColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String label,
    List<({String? avatarUrl, String nickname})> members,
    double diameter,
    Color? borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          AvatarDividedCircle(
            members: members,
            diameter: diameter,
            borderColor: borderColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  members.map((m) => m.nickname).join(', '),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeDemo(
    String label,
    List<({String? avatarUrl, String nickname})> members,
    double diameter,
    Color? borderColor,
  ) {
    return Column(
      children: [
        AvatarDividedCircle(
          members: members,
          diameter: diameter,
          borderColor: borderColor,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
