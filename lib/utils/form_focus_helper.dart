import 'dart:async';

import 'package:flutter/material.dart';

/// Validates a form and scrolls/focuses its first invalid field.
bool validateAndFocusFirstError(GlobalKey<FormState> formKey) {
  final formState = formKey.currentState;
  if (formState == null) return false;
  if (formState.validate()) return true;

  final formContext = formKey.currentContext;
  if (formContext != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_focusFirstInvalidField(formContext));
    });
  }
  return false;
}

/// Scrolls to a custom required control and focuses its first focusable child.
Future<void> focusRequiredWidget(GlobalKey key) async {
  final context = key.currentContext;
  if (context == null) return;
  await _scrollAndFocus(context);
}

Future<void> _focusFirstInvalidField(BuildContext formContext) async {
  if (!formContext.mounted) return;
  FormFieldState<dynamic>? firstInvalid;

  void findInvalid(Element element) {
    if (firstInvalid != null) return;
    if (element is StatefulElement &&
        element.state is FormFieldState<dynamic>) {
      final field = element.state as FormFieldState<dynamic>;
      if (field.hasError) {
        firstInvalid = field;
        return;
      }
    }
    element.visitChildElements(findInvalid);
  }

  (formContext as Element).visitChildElements(findInvalid);
  final fieldContext = firstInvalid?.context;
  if (fieldContext != null) await _scrollAndFocus(fieldContext);
}

Future<void> _scrollAndFocus(BuildContext context) async {
  if (!context.mounted) return;
  try {
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  } catch (_) {
    // Non-scrollable forms still receive focus below.
  }
  if (!context.mounted) return;

  final root = context as Element;
  FocusNode? firstNode;
  void findFocusNode(Element element) {
    if (firstNode != null) return;
    final node = Focus.maybeOf(element, scopeOk: false);
    final nodeContext = node?.context;
    if (node != null && node.canRequestFocus && nodeContext != null) {
      var isInsideRoot = identical(nodeContext, root);
      if (!isInsideRoot) {
        nodeContext.visitAncestorElements((ancestor) {
          if (identical(ancestor, root)) {
            isInsideRoot = true;
            return false;
          }
          return true;
        });
      }
      if (isInsideRoot) {
        firstNode = node;
        return;
      }
    }
    element.visitChildElements(findFocusNode);
  }

  findFocusNode(root);
  firstNode?.requestFocus();
}
