// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => defineTests();

void defineTests() {
  group('textMouseCursor', () {
    Future<MouseCursor?> cursorAt(WidgetTester tester, Offset position) async {
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: position);
      await tester.pump();
      return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
    }

    Future<void> pumpMarkdown(WidgetTester tester, String data, {MouseCursor? cursor}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: MarkdownBody(
              data: data,
              softLineBreak: true,
              textMouseCursor: cursor,
              onTapLink: (_, __, ___) {},
            ),
          ),
        ),
      ));
    }

    testWidgets('shows the given cursor over text', (WidgetTester tester) async {
      await pumpMarkdown(tester, 'Hello **bold**', cursor: SystemMouseCursors.text);

      final Offset textStart = tester.getTopLeft(find.byType(RichText).first) + const Offset(4, 4);
      expect(await cursorAt(tester, textStart), SystemMouseCursors.text);
    });

    testWidgets('does not apply the cursor outside the glyphs', (WidgetTester tester) async {
      await pumpMarkdown(tester, 'A much longer first line\nHi', cursor: SystemMouseCursors.text);

      // 2行目は短いので、Textの右下は文字のない余白になる
      final Offset blankArea = tester.getBottomRight(find.byType(RichText).first) + const Offset(-4, -4);
      expect(await cursorAt(tester, blankArea), SystemMouseCursors.basic);
    });

    testWidgets('keeps the click cursor on links', (WidgetTester tester) async {
      await pumpMarkdown(tester, '[link](https://example.com)', cursor: SystemMouseCursors.text);

      final Offset linkStart = tester.getTopLeft(find.byType(RichText).first) + const Offset(4, 4);
      expect(await cursorAt(tester, linkStart), SystemMouseCursors.click);
    });

    testWidgets('keeps the default SelectionArea behavior when null', (WidgetTester tester) async {
      await pumpMarkdown(tester, 'A much longer first line\nHi');

      // Text自身のMouseRegionにより、余白も含めてテキストカーソルになる
      final Offset blankArea = tester.getBottomRight(find.byType(RichText).first) + const Offset(-4, -4);
      expect(await cursorAt(tester, blankArea), SystemMouseCursors.text);
    });
  });
}
