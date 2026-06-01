import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import 'animations.dart';

class StandardCalculatorPage extends StatelessWidget {
  const StandardCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bgBottom,
      appBar: AppBar(
        backgroundColor: tokens.bgBottom,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Standard Calculator'),
      ),
      body: const SafeArea(child: StandardCalculatorSection()),
    );
  }
}

class StandardCalculatorSection extends StatefulWidget {
  const StandardCalculatorSection({super.key});

  @override
  State<StandardCalculatorSection> createState() =>
      _StandardCalculatorSectionState();
}

class _StandardCalculatorSectionState extends State<StandardCalculatorSection>
    with AutomaticKeepAliveClientMixin {
  late final _StandardCalculatorController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = _StandardCalculatorController();
    _controller.restoreHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = AppThemeTokens.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      children: [
        const _SpringParticleTextHeader(
          title: 'GradeCalcProDz',
          subtitle: 'By H7Z man',
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: tokens.cardRadius,
          blur: 12,
          opacity: 0.07,
          borderColor: tokens.fieldBorder.withValues(alpha: 0.58),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ValueListenableBuilder<_CalculatorSnapshot>(
                valueListenable: _controller,
                builder: (context, snapshot, _) {
                  return _CalculatorDisplay(snapshot: snapshot);
                },
              ),
              const SizedBox(height: 14),
              _CalculatorKeypad(controller: _controller),
              const SizedBox(height: 14),
              ValueListenableBuilder<_CalculatorSnapshot>(
                valueListenable: _controller,
                builder: (context, snapshot, _) {
                  return SizedBox(
                    height: 206,
                    child: _CalculatorHistoryPanel(
                      history: snapshot.history,
                      onUse: _controller.useHistoryValue,
                      onClear: _controller.clearHistory,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalculatorDisplay extends StatelessWidget {
  const _CalculatorDisplay({required this.snapshot});

  final _CalculatorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final hasError = snapshot.errorMessage != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: tokens.field,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasError
              ? tokens.danger.withValues(alpha: 0.42)
              : tokens.fieldBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            snapshot.expression.isEmpty ? 'Ready' : snapshot.expression,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasError ? tokens.danger : tokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              hasError ? snapshot.errorMessage! : snapshot.display,
              textAlign: TextAlign.right,
              style: theme.textTheme.displaySmall?.copyWith(
                color: hasError ? tokens.danger : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorKeypad extends StatelessWidget {
  const _CalculatorKeypad({required this.controller});

  final _StandardCalculatorController controller;

  static const List<_CalculatorKeySpec> _keys = [
    _CalculatorKeySpec.clear(),
    _CalculatorKeySpec.parenthesis('('),
    _CalculatorKeySpec.parenthesis(')'),
    _CalculatorKeySpec.operator('/'),
    _CalculatorKeySpec.digit('7'),
    _CalculatorKeySpec.digit('8'),
    _CalculatorKeySpec.digit('9'),
    _CalculatorKeySpec.operator('*'),
    _CalculatorKeySpec.digit('4'),
    _CalculatorKeySpec.digit('5'),
    _CalculatorKeySpec.digit('6'),
    _CalculatorKeySpec.operator('-'),
    _CalculatorKeySpec.digit('1'),
    _CalculatorKeySpec.digit('2'),
    _CalculatorKeySpec.digit('3'),
    _CalculatorKeySpec.operator('+'),
    _CalculatorKeySpec.digit('0'),
    _CalculatorKeySpec.decimal(),
    _CalculatorKeySpec.backspace(),
    _CalculatorKeySpec.equals(),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];
        return _CalculatorButton(
          spec: key,
          onPressed: () => controller.handle(key),
        );
      },
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({required this.spec, required this.onPressed});

  final _CalculatorKeySpec spec;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final buttonColor = switch (spec.role) {
      _CalculatorKeyRole.digit => tokens.card,
      _CalculatorKeyRole.decimal => tokens.card,
      _CalculatorKeyRole.operator => tokens.accent.withValues(alpha: 0.14),
      _CalculatorKeyRole.parenthesis => tokens.accent.withValues(alpha: 0.09),
      _CalculatorKeyRole.equals => tokens.accent,
      _CalculatorKeyRole.clear => tokens.danger.withValues(alpha: 0.12),
      _CalculatorKeyRole.backspace => tokens.danger.withValues(alpha: 0.08),
    };
    final foreground = switch (spec.role) {
      _CalculatorKeyRole.digit => theme.colorScheme.onSurface,
      _CalculatorKeyRole.decimal => theme.colorScheme.onSurface,
      _CalculatorKeyRole.operator => tokens.accent,
      _CalculatorKeyRole.parenthesis => tokens.accent,
      _CalculatorKeyRole.equals => theme.colorScheme.onPrimary,
      _CalculatorKeyRole.clear => tokens.danger,
      _CalculatorKeyRole.backspace => tokens.danger,
    };

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: Center(
          child: Text(
            spec.label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorHistoryPanel extends StatelessWidget {
  const _CalculatorHistoryPanel({
    required this.history,
    required this.onUse,
    required this.onClear,
  });

  final List<_CalculatorHistoryEntry> history;
  final ValueChanged<String> onUse;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (history.isNotEmpty)
              TextButton.icon(
                key: const ValueKey('calculator-clear-history'),
                onPressed: onClear,
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.danger,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: history.isEmpty
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'No calculations yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CalculatorHistoryTile(
                        entry: entry,
                        onUse: () => onUse(entry.result),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CalculatorHistoryTile extends StatelessWidget {
  const _CalculatorHistoryTile({required this.entry, required this.onUse});

  final _CalculatorHistoryEntry entry;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Material(
      color: tokens.field,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.expression,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.result,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onUse,
                icon: const Icon(Icons.add_rounded, size: 18),
                tooltip: 'Use result',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CalculatorKeyRole {
  digit,
  decimal,
  operator,
  parenthesis,
  equals,
  clear,
  backspace,
}

class _CalculatorKeySpec {
  const _CalculatorKeySpec._(this.label, this.role, this.value);

  const _CalculatorKeySpec.digit(String value)
    : this._(value, _CalculatorKeyRole.digit, value);

  const _CalculatorKeySpec.decimal()
    : this._('.', _CalculatorKeyRole.decimal, '.');

  const _CalculatorKeySpec.operator(String value)
    : this._(value, _CalculatorKeyRole.operator, value);

  const _CalculatorKeySpec.parenthesis(String value)
    : this._(value, _CalculatorKeyRole.parenthesis, value);

  const _CalculatorKeySpec.equals()
    : this._('=', _CalculatorKeyRole.equals, '=');

  const _CalculatorKeySpec.clear() : this._('C', _CalculatorKeyRole.clear, 'C');

  const _CalculatorKeySpec.backspace()
    : this._('DEL', _CalculatorKeyRole.backspace, 'backspace');

  final String label;
  final _CalculatorKeyRole role;
  final String value;
}

@immutable
class _CalculatorSnapshot {
  const _CalculatorSnapshot({
    required this.display,
    required this.expression,
    required this.history,
    this.errorMessage,
  });

  static const initial = _CalculatorSnapshot(
    display: '0',
    expression: '',
    history: [],
  );

  final String display;
  final String expression;
  final List<_CalculatorHistoryEntry> history;
  final String? errorMessage;
}

@immutable
class _CalculatorHistoryEntry {
  const _CalculatorHistoryEntry({
    required this.expression,
    required this.result,
  });

  final String expression;
  final String result;

  bool matches(String nextExpression, String nextResult) {
    return expression == nextExpression && result == nextResult;
  }
}

class _CalculatorHistoryStore {
  const _CalculatorHistoryStore._();

  static const String _storageKey =
      'standard_calculator_section_history_entries_v1';

  static final List<_CalculatorHistoryEntry> _entries =
      <_CalculatorHistoryEntry>[];
  static bool _restored = false;

  static Future<List<_CalculatorHistoryEntry>> restore() async {
    if (_restored) {
      return snapshot();
    }
    _restored = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rows = prefs.getStringList(_storageKey) ?? const <String>[];
      final restored = <_CalculatorHistoryEntry>[];
      for (final row in rows) {
        try {
          final decoded = jsonDecode(row);
          if (decoded is! Map<String, dynamic>) {
            continue;
          }
          final expression = decoded['expression'];
          final result = decoded['result'];
          if (expression is! String || result is! String) {
            continue;
          }
          restored.add(
            _CalculatorHistoryEntry(expression: expression, result: result),
          );
        } catch (_) {
          continue;
        }
      }
      _entries
        ..clear()
        ..addAll(restored);
    } catch (_) {
      // If storage is unavailable, calculator still works with in-memory history.
    }

    return snapshot();
  }

  static List<_CalculatorHistoryEntry> snapshot() {
    return List<_CalculatorHistoryEntry>.of(_entries);
  }

  static void save(List<_CalculatorHistoryEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
    _persist();
  }

  static void clear() {
    _entries.clear();
    _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rows = _entries
          .map(
            (entry) => jsonEncode({
              'expression': entry.expression,
              'result': entry.result,
            }),
          )
          .toList(growable: false);
      await prefs.setStringList(_storageKey, rows);
    } catch (_) {
      // Ignore persistence failures and keep calculator usable.
    }
  }
}

class _StandardCalculatorController extends ValueNotifier<_CalculatorSnapshot> {
  _StandardCalculatorController()
    : _history = _CalculatorHistoryStore.snapshot(),
      super(_CalculatorSnapshot.initial) {
    _publish();
  }

  static const int _maxExpressionLength = 72;
  static const int _maxHistoryItems = 12;

  final List<_CalculatorHistoryEntry> _history;
  String _expression = '';
  String _caption = '';
  String? _errorMessage;
  bool _justEvaluated = false;
  bool _disposed = false;

  Future<void> restoreHistory() async {
    final restored = await _CalculatorHistoryStore.restore();
    if (_disposed) {
      return;
    }
    _history
      ..clear()
      ..addAll(restored.take(_maxHistoryItems));
    _publish();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void handle(_CalculatorKeySpec key) {
    switch (key.role) {
      case _CalculatorKeyRole.digit:
        _appendDigit(key.value);
      case _CalculatorKeyRole.decimal:
        _appendDecimal();
      case _CalculatorKeyRole.operator:
        _appendOperator(key.value);
      case _CalculatorKeyRole.parenthesis:
        _appendParenthesis(key.value);
      case _CalculatorKeyRole.equals:
        _evaluate();
      case _CalculatorKeyRole.clear:
        _clear();
      case _CalculatorKeyRole.backspace:
        _backspace();
    }
  }

  void _appendDigit(String digit) {
    _prepareForEntry();
    if (_expression == '0') {
      _expression = digit;
    } else {
      _appendRaw(digit);
    }
    _publish();
  }

  void _appendDecimal() {
    _prepareForEntry();
    if (_expression.isEmpty || _endsWithOperator(_expression) || _last == '(') {
      _appendRaw('0.');
      _publish();
      return;
    }

    if (_last == ')') {
      _appendRaw('*0.');
      _publish();
      return;
    }

    if (!_currentNumberContainsDecimal()) {
      _appendRaw('.');
    }
    _publish();
  }

  void _appendOperator(String operator) {
    if (_errorMessage != null && operator != '-') {
      _resetExpression();
      _publish();
      return;
    }

    _prepareForEntry(keepResult: true);
    if (_expression.isEmpty) {
      if (operator == '-') {
        _appendRaw('-');
      }
      _publish();
      return;
    }

    if (_last == '(') {
      if (operator == '-') {
        _appendRaw('-');
      }
      _publish();
      return;
    }

    if (_endsWithOperator(_expression)) {
      _expression =
          '${_expression.substring(0, _expression.length - 1)}$operator';
    } else {
      _appendRaw(operator);
    }
    _publish();
  }

  void _appendParenthesis(String parenthesis) {
    _prepareForEntry();
    if (parenthesis == '(') {
      if (_expression.isNotEmpty && (_last == ')' || _lastIsNumberLike)) {
        _appendRaw('*(');
      } else {
        _appendRaw('(');
      }
      _publish();
      return;
    }

    if (_openParenthesisCount <= 0 ||
        _expression.isEmpty ||
        _endsWithOperator(_expression) ||
        _last == '(') {
      _publish();
      return;
    }

    _appendRaw(')');
    _publish();
  }

  void _backspace() {
    if (_errorMessage != null) {
      _resetExpression();
      _publish();
      return;
    }
    if (_justEvaluated) {
      _resetExpression();
      _publish();
      return;
    }
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _caption = '';
    _publish();
  }

  void _evaluate() {
    if (_errorMessage != null) {
      _clear();
      return;
    }
    if (_justEvaluated) {
      _publish();
      return;
    }

    final rawExpression = _expression.trim();
    if (rawExpression.isEmpty) {
      _publish();
      return;
    }

    try {
      final result = _ExpressionParser(rawExpression).parse();
      if (result.isNaN || result.isInfinite) {
        throw const _CalculatorParseException('Math error');
      }
      final resultText = _formatNumber(result);
      _saveHistoryEntry(rawExpression, resultText);
      _expression = resultText;
      _caption = '$rawExpression =';
      _errorMessage = null;
      _justEvaluated = true;
    } on _CalculatorParseException catch (error) {
      _errorMessage = error.message;
      _caption = rawExpression;
    }
    _publish();
  }

  void _saveHistoryEntry(String expression, String result) {
    if (_history.isNotEmpty && _history.first.matches(expression, result)) {
      return;
    }
    _history.insert(
      0,
      _CalculatorHistoryEntry(expression: expression, result: result),
    );
    if (_history.length > _maxHistoryItems) {
      _history.removeRange(_maxHistoryItems, _history.length);
    }
    _CalculatorHistoryStore.save(_history);
  }

  void useHistoryValue(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      _errorMessage = 'Invalid history value';
      _publish();
      return;
    }

    _errorMessage = null;
    if (_expression.isEmpty || _expression == '0' || _justEvaluated) {
      _expression = value;
    } else if (_last == ')' || _lastIsNumberLike) {
      _appendRaw('*$value');
    } else {
      _appendRaw(value);
    }
    _caption = '';
    _justEvaluated = false;
    _publish();
  }

  void clearHistory() {
    if (_history.isEmpty) {
      return;
    }
    _history.clear();
    _CalculatorHistoryStore.clear();
    _publish();
  }

  void _clear() {
    _resetExpression();
    _publish();
  }

  void _prepareForEntry({bool keepResult = false}) {
    if (_errorMessage != null) {
      _resetExpression();
    }
    if (_justEvaluated && !keepResult) {
      _expression = '';
    }
    _caption = '';
    _justEvaluated = false;
  }

  void _resetExpression() {
    _expression = '';
    _caption = '';
    _errorMessage = null;
    _justEvaluated = false;
  }

  void _appendRaw(String text) {
    if (_expression.length + text.length <= _maxExpressionLength) {
      _expression += text;
    }
  }

  void _publish() {
    value = _CalculatorSnapshot(
      display: _errorMessage == null
          ? (_expression.isEmpty ? '0' : _expression)
          : (_expression.isEmpty ? '0' : _expression),
      expression: _buildCaption(),
      history: List<_CalculatorHistoryEntry>.unmodifiable(_history),
      errorMessage: _errorMessage,
    );
  }

  String _buildCaption() {
    if (_errorMessage != null) {
      return _caption.isEmpty ? 'Clear and try again' : _caption;
    }
    return _caption.isEmpty
        ? (_expression.isEmpty ? '' : _expression)
        : _caption;
  }

  String get _last =>
      _expression.isEmpty ? '' : _expression[_expression.length - 1];

  bool get _lastIsNumberLike {
    if (_expression.isEmpty) {
      return false;
    }
    final code = _last.codeUnitAt(0);
    return (code >= 48 && code <= 57) || _last == '.';
  }

  int get _openParenthesisCount {
    var count = 0;
    for (var index = 0; index < _expression.length; index++) {
      final char = _expression[index];
      if (char == '(') {
        count++;
      } else if (char == ')') {
        count--;
      }
    }
    return count;
  }

  bool _currentNumberContainsDecimal() {
    for (var index = _expression.length - 1; index >= 0; index--) {
      final char = _expression[index];
      if (char == '.') {
        return true;
      }
      if (_isOperator(char) || char == '(' || char == ')') {
        return false;
      }
    }
    return false;
  }

  bool _endsWithOperator(String value) {
    return value.isNotEmpty && _isOperator(value[value.length - 1]);
  }

  bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '*' || value == '/';
  }

  String _formatNumber(double value) {
    final normalized = value.abs() < 0.000000001 ? 0.0 : value;
    final absolute = normalized.abs();
    if (absolute >= 1000000000000 || (absolute > 0 && absolute < 0.000001)) {
      return normalized.toStringAsExponential(6);
    }

    var text = normalized.toStringAsFixed(8);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }
}

class _CalculatorParseException implements Exception {
  const _CalculatorParseException(this.message);

  final String message;
}

class _ExpressionParser {
  _ExpressionParser(this.source);

  final String source;
  int _index = 0;

  double parse() {
    final value = _parseExpression();
    _skipWhitespace();
    if (_index != source.length) {
      throw const _CalculatorParseException('Invalid expression');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const _CalculatorParseException('Cannot divide by zero');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipWhitespace();
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('(')) {
      final value = _parseExpression();
      _skipWhitespace();
      if (!_match(')')) {
        throw const _CalculatorParseException('Missing closing parenthesis');
      }
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipWhitespace();
    final start = _index;
    var hasDigit = false;
    var hasDecimal = false;

    while (_index < source.length) {
      final char = source[_index];
      final code = char.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        hasDigit = true;
        _index++;
      } else if (char == '.' && !hasDecimal) {
        hasDecimal = true;
        _index++;
      } else {
        break;
      }
    }

    if (!hasDigit) {
      throw const _CalculatorParseException('Invalid number');
    }

    final value = double.tryParse(source.substring(start, _index));
    if (value == null) {
      throw const _CalculatorParseException('Invalid number');
    }
    return value;
  }

  bool _match(String char) {
    if (_index < source.length && source[_index] == char) {
      _index++;
      return true;
    }
    return false;
  }

  void _skipWhitespace() {
    while (_index < source.length && source.codeUnitAt(_index) == 32) {
      _index++;
    }
  }
}

class _SpringParticleTextHeader extends StatelessWidget {
  const _SpringParticleTextHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        height: 184,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? tokens.card.withValues(alpha: 0.74)
              : tokens.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.56)),
          boxShadow: [
            BoxShadow(
              color: tokens.shadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.cardRadius - 8),
          child: SpringParticleText(
            lines: [title, subtitle],
            lineScales: const [1, 0.68],
          ),
        ),
      ),
    );
  }
}

class SpringParticleText extends StatefulWidget {
  const SpringParticleText({
    super.key,
    required this.lines,
    this.lineScales = const [],
    this.height,
    this.dotColor,
    this.glowColor,
    this.semanticsLabel,
  });

  final List<String> lines;
  final List<double> lineScales;
  final double? height;
  final Color? dotColor;
  final Color? glowColor;
  final String? semanticsLabel;

  @override
  State<SpringParticleText> createState() => _SpringParticleTextState();
}

class _SpringParticleTextState extends State<SpringParticleText>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final _SpringTextParticleEngine _engine;
  Duration? _lastTick;
  ScrollableState? _scrollableState;
  ScrollPosition? _scrollPosition;
  bool _tickerModeEnabled = true;
  bool _lifecyclePaused = false;
  bool _isVisibleInViewport = true;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = _SpringTextParticleEngine(lines: _particleLines);
    _ticker = createTicker(_onTick);
  }

  List<_ParticleTextLine> get _particleLines => [
    for (var index = 0; index < widget.lines.length; index++)
      _ParticleTextLine(
        widget.lines[index],
        scale: index < widget.lineScales.length ? widget.lineScales[index] : 1,
      ),
  ];

  @override
  void didUpdateWidget(covariant SpringParticleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePublicLines(oldWidget, widget)) {
      _engine.setLines(_particleLines);
      _applyTickerGate();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerModeEnabled = TickerMode.of(context);
    _bindScrollPosition();
    _scheduleVisibilityCheck();
    _applyTickerGate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecyclePaused = state != AppLifecycleState.resumed;
    _applyTickerGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _stopTicker();
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null) {
      return;
    }

    final deltaSeconds =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final shouldContinue = _engine.step(deltaSeconds);
    if (!shouldContinue) {
      _stopTicker();
    }
  }

  void _startTicker() {
    if (_ticker.isActive || _engine.isPaused) {
      return;
    }
    _lastTick = null;
    _ticker.start();
  }

  void _stopTicker() {
    if (!_ticker.isActive) {
      return;
    }
    _ticker.stop();
    _lastTick = null;
  }

  void _setTouch(Offset position) {
    _engine.setTouch(position);
    _startTicker();
  }

  void _clearTouch() {
    _engine.clearTouch();
    _startTicker();
  }

  void _bindScrollPosition() {
    final nextScrollable = Scrollable.maybeOf(context);
    final nextPosition = nextScrollable?.position;
    if (identical(nextPosition, _scrollPosition)) {
      _scrollableState = nextScrollable;
      return;
    }

    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _scrollableState = nextScrollable;
    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_scheduleVisibilityCheck);
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) {
      return;
    }
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted) {
        return;
      }
      final nextVisible = _computeViewportVisibility();
      if (_isVisibleInViewport == nextVisible) {
        return;
      }
      _isVisibleInViewport = nextVisible;
      _applyTickerGate();
    });
  }

  bool _computeViewportVisibility() {
    final scrollableState = _scrollableState;
    if (scrollableState == null) {
      return true;
    }

    final renderObject = context.findRenderObject();
    final viewportObject = scrollableState.context.findRenderObject();
    if (renderObject is! RenderBox ||
        viewportObject is! RenderBox ||
        !renderObject.attached ||
        !viewportObject.attached ||
        !renderObject.hasSize ||
        !viewportObject.hasSize) {
      return true;
    }

    try {
      final offset = renderObject.localToGlobal(
        Offset.zero,
        ancestor: viewportObject,
      );
      final childRect = offset & renderObject.size;
      final viewportRect = Offset.zero & viewportObject.size;
      return childRect.overlaps(viewportRect.inflate(32));
    } catch (_) {
      return true;
    }
  }

  void _applyTickerGate() {
    final shouldPause =
        !_tickerModeEnabled || _lifecyclePaused || !_isVisibleInViewport;
    _engine.setPaused(shouldPause);
    if (shouldPause) {
      _stopTicker();
    } else if (_engine.hasMotion) {
      _startTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final dotColor = widget.dotColor ?? tokens.accent;
    final glowColor = widget.glowColor ?? tokens.glow;

    final painter = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _engine.configure(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _setTouch(details.localPosition),
          onPanUpdate: (details) => _setTouch(details.localPosition),
          onPanEnd: (_) => _clearTouch(),
          onPanCancel: _clearTouch,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _SpringParticleTextPainter(
                engine: _engine,
                dotColor: dotColor,
                glowColor: glowColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );

    final boundedPainter = widget.height == null
        ? painter
        : SizedBox(height: widget.height, child: painter);

    return Semantics(
      label: widget.semanticsLabel ?? widget.lines.join('\n'),
      child: RepaintBoundary(child: boundedPainter),
    );
  }

  bool _samePublicLines(SpringParticleText previous, SpringParticleText next) {
    if (previous.lines.length != next.lines.length ||
        previous.lineScales.length != next.lineScales.length) {
      return false;
    }
    for (var i = 0; i < next.lines.length; i++) {
      if (previous.lines[i] != next.lines[i]) {
        return false;
      }
    }
    for (var i = 0; i < next.lineScales.length; i++) {
      if (previous.lineScales[i] != next.lineScales[i]) {
        return false;
      }
    }
    return true;
  }
}

class _ParticleConfig {
  const _ParticleConfig({
    this.maxParticles = 1320,
    this.spring = 42,
    this.damping = 0.84,
    this.repel = 2600,
    this.repelRadius = 52,
    this.settleDistance = 0.12,
    this.settleVelocity = 0.12,
  }) : assert(maxParticles > 0),
       assert(spring > 0),
       assert(damping > 0 && damping < 1),
       assert(repel > 0),
       assert(repelRadius > 0),
       assert(settleDistance > 0),
       assert(settleVelocity > 0);

  final int maxParticles;
  final double spring;
  final double damping;
  final double repel;
  final double repelRadius;
  final double settleDistance;
  final double settleVelocity;
}

class _ParticleTextLine {
  const _ParticleTextLine(this.text, {this.scale = 1});

  final String text;
  final double scale;
}

class _SpringTextParticleEngine extends ChangeNotifier {
  _SpringTextParticleEngine({
    required List<_ParticleTextLine> lines,
    _ParticleConfig config = const _ParticleConfig(maxParticles: 1800),
  }) : _lines = List<_ParticleTextLine>.unmodifiable(lines),
       _config = config,
       _particles = List<_SpringParticle>.generate(
         config.maxParticles,
         (_) => _SpringParticle(),
       ),
       _anchorX = Float32List(config.maxParticles),
       _anchorY = Float32List(config.maxParticles),
       _points = Float32List(config.maxParticles * 2) {
    _parkInactivePoints(0);
  }

  static const double _offscreen = -10000;
  static const int _rowCount = 7;

  final _ParticleConfig _config;
  final List<_SpringParticle> _particles;
  final Float32List _anchorX;
  final Float32List _anchorY;
  final Float32List _points;

  List<_ParticleTextLine> _lines;
  Size _lastSize = Size.zero;
  int _activeCount = 0;
  double _pointStrokeWidth = 3;
  bool _configured = false;
  bool _hasMotion = false;
  bool _touchActive = false;
  bool _paused = false;
  double _touchX = 0;
  double _touchY = 0;

  Float32List get points => _points;
  double get pointStrokeWidth => _pointStrokeWidth;
  bool get hasMotion => _hasMotion || _touchActive;
  bool get isPaused => _paused;

  void setLines(List<_ParticleTextLine> lines) {
    if (_sameLines(lines)) {
      return;
    }
    _lines = List<_ParticleTextLine>.unmodifiable(lines);
    _configured = false;
    _hasMotion = true;
  }

  void setPaused(bool paused) {
    _paused = paused;
  }

  void configure(Size size) {
    final safeWidth = size.width.isFinite ? size.width : 0.0;
    final safeHeight = size.height.isFinite ? size.height : 0.0;
    if (safeWidth <= 0 || safeHeight <= 0 || _lines.isEmpty) {
      return;
    }

    final normalizedSize = Size(safeWidth, safeHeight);
    if (_configured && normalizedSize == _lastSize) {
      return;
    }

    final previousCount = _activeCount;
    final wasConfigured = _configured;
    _lastSize = normalizedSize;

    var maxScaledColumns = 0.0;
    var totalScaledRows = 0.0;
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final scale = line.scale.clamp(0.42, 1.0);
      final columns = _totalGlyphColumns(line.text);
      if (columns <= 0) {
        continue;
      }
      maxScaledColumns = math.max(maxScaledColumns, columns * scale);
      totalScaledRows += _rowCount * scale;
      if (i < _lines.length - 1) {
        totalScaledRows += 1.35;
      }
    }

    if (maxScaledColumns <= 0 || totalScaledRows <= 0) {
      _activeCount = 0;
      _parkInactivePoints(0);
      _configured = true;
      return;
    }

    final horizontalPadding = math.max(10.0, safeWidth * 0.035);
    final verticalPadding = math.max(10.0, safeHeight * 0.16);
    final availableWidth = math.max(1.0, safeWidth - horizontalPadding * 2);
    final availableHeight = math.max(1.0, safeHeight - verticalPadding * 2);
    final cell = math.max(
      2.5,
      math.min(
        availableWidth / maxScaledColumns,
        availableHeight / totalScaledRows,
      ),
    );
    final contentHeight = totalScaledRows * cell;
    final top = (safeHeight - contentHeight) / 2;

    var count = 0;
    var lineTop = top;
    for (var lineIndex = 0; lineIndex < _lines.length; lineIndex++) {
      final line = _lines[lineIndex];
      final lineScale = line.scale.clamp(0.42, 1.0);
      final lineColumns = _totalGlyphColumns(line.text);
      if (lineColumns <= 0) {
        continue;
      }

      final lineCell = cell * lineScale;
      final sample = lineCell >= 7.5 ? 2 : 1;
      final subStep = lineCell / sample;
      final contentWidth = lineColumns * lineCell;
      final left = (safeWidth - contentWidth) / 2;
      var cursorColumn = 0.0;

      for (var charIndex = 0; charIndex < line.text.length; charIndex++) {
        final glyph = _DotGlyphs.forCodeUnit(line.text.codeUnitAt(charIndex));
        final glyphWidth = glyph.first.length;
        for (var glyphY = 0; glyphY < glyph.length; glyphY++) {
          final row = glyph[glyphY];
          for (var glyphX = 0; glyphX < glyphWidth; glyphX++) {
            if (row.codeUnitAt(glyphX) == _DotGlyphs.empty) {
              continue;
            }
            for (var sy = 0; sy < sample; sy++) {
              for (var sx = 0; sx < sample; sx++) {
                if (count >= _config.maxParticles) {
                  break;
                }
                _anchorX[count] =
                    left +
                    (cursorColumn + glyphX) * lineCell +
                    (sx + 0.5) * subStep;
                _anchorY[count] =
                    lineTop + glyphY * lineCell + (sy + 0.5) * subStep;
                count++;
              }
              if (count >= _config.maxParticles) {
                break;
              }
            }
          }
        }
        cursorColumn += glyphWidth + 1;
      }

      lineTop += (_rowCount * lineScale + 1.35) * cell;
    }

    _activeCount = count;
    _pointStrokeWidth = math.max(2.1, math.min(5.0, cell * 0.34));

    for (var i = 0; i < _activeCount; i++) {
      final particle = _particles[i];
      particle.targetX = _anchorX[i];
      particle.targetY = _anchorY[i];
      if (!wasConfigured || i >= previousCount || !particle.ready) {
        particle.x = particle.targetX;
        particle.y = particle.targetY;
        particle.vx = 0;
        particle.vy = 0;
        particle.ready = true;
      } else {
        _hasMotion = true;
      }
      _points[i * 2] = particle.x;
      _points[i * 2 + 1] = particle.y;
    }

    _parkInactivePoints(_activeCount);
    _configured = true;
  }

  void setTouch(Offset localPosition) {
    if (!_configured || _paused) {
      return;
    }
    _touchActive = true;
    _touchX = localPosition.dx;
    _touchY = localPosition.dy;
    _hasMotion = true;
  }

  void clearTouch() {
    _touchActive = false;
    _hasMotion = true;
  }

  bool step(double deltaSeconds) {
    if (!_configured || _paused || _activeCount == 0) {
      return false;
    }

    final dt = deltaSeconds.clamp(0.001, 0.034);
    final damping = math.pow(_config.damping, dt * 60).toDouble();
    final repelRadiusSquared = _config.repelRadius * _config.repelRadius;
    var moving = _touchActive;

    for (var i = 0; i < _activeCount; i++) {
      final particle = _particles[i];
      var ax = (particle.targetX - particle.x) * _config.spring;
      var ay = (particle.targetY - particle.y) * _config.spring;

      if (_touchActive) {
        final awayX = particle.x - _touchX;
        final awayY = particle.y - _touchY;
        final distanceSquared = awayX * awayX + awayY * awayY;
        if (distanceSquared < repelRadiusSquared) {
          final distance = math.sqrt(math.max(distanceSquared, 0.001));
          final falloff = 1 - distance / _config.repelRadius;
          final repel = _config.repel * falloff * falloff;
          ax += awayX / distance * repel;
          ay += awayY / distance * repel;
        }
      }

      particle.vx = (particle.vx + ax * dt) * damping;
      particle.vy = (particle.vy + ay * dt) * damping;
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;

      _points[i * 2] = particle.x;
      _points[i * 2 + 1] = particle.y;

      final dx = particle.targetX - particle.x;
      final dy = particle.targetY - particle.y;
      if (dx.abs() > _config.settleDistance ||
          dy.abs() > _config.settleDistance ||
          particle.vx.abs() > _config.settleVelocity ||
          particle.vy.abs() > _config.settleVelocity) {
        moving = true;
      }
    }

    _hasMotion = moving;
    notifyListeners();
    return moving;
  }

  double _totalGlyphColumns(String text) {
    var columns = 0.0;
    for (var i = 0; i < text.length; i++) {
      columns += _DotGlyphs.forCodeUnit(text.codeUnitAt(i)).first.length;
      if (i < text.length - 1) {
        columns += 1;
      }
    }
    return columns;
  }

  bool _sameLines(List<_ParticleTextLine> lines) {
    if (_lines.length != lines.length) {
      return false;
    }
    for (var i = 0; i < lines.length; i++) {
      if (_lines[i].text != lines[i].text ||
          _lines[i].scale != lines[i].scale) {
        return false;
      }
    }
    return true;
  }

  void _parkInactivePoints(int startIndex) {
    for (var i = startIndex; i < _config.maxParticles; i++) {
      _points[i * 2] = _offscreen;
      _points[i * 2 + 1] = _offscreen;
    }
  }
}

class _SpringParticle {
  double x = 0;
  double y = 0;
  double targetX = 0;
  double targetY = 0;
  double vx = 0;
  double vy = 0;
  bool ready = false;
}

class _SpringParticleTextPainter extends CustomPainter {
  _SpringParticleTextPainter({
    required this.engine,
    required this.dotColor,
    required this.glowColor,
  }) : super(repaint: engine);

  final _SpringTextParticleEngine engine;
  final Color dotColor;
  final Color glowColor;
  final Paint _dotPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _glowPaint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    _glowPaint
      ..color = glowColor.withValues(alpha: 0.72)
      ..strokeWidth = engine.pointStrokeWidth * 2.7;
    canvas.drawRawPoints(ui.PointMode.points, engine.points, _glowPaint);

    _dotPaint
      ..color = dotColor
      ..strokeWidth = engine.pointStrokeWidth;
    canvas.drawRawPoints(ui.PointMode.points, engine.points, _dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SpringParticleTextPainter oldDelegate) {
    return oldDelegate.engine != engine ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.glowColor != glowColor;
  }
}

class _DotGlyphs {
  const _DotGlyphs._();

  static const int empty = 48;

  static const List<String> fallback = [
    '11111',
    '10001',
    '00010',
    '00100',
    '00100',
    '00000',
    '00100',
  ];

  static const Map<int, List<String>> _glyphs = {
    32: ['000', '000', '000', '000', '000', '000', '000'],
    55: ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    66: ['11110', '10001', '10001', '11110', '10001', '10001', '11110'],
    67: ['01111', '10000', '10000', '10000', '10000', '10000', '01111'],
    68: ['11110', '10001', '10001', '10001', '10001', '10001', '11110'],
    71: ['01110', '10001', '10000', '10111', '10001', '10001', '01110'],
    72: ['10001', '10001', '10001', '11111', '10001', '10001', '10001'],
    80: ['11110', '10001', '10001', '11110', '10000', '10000', '10000'],
    90: ['11111', '00001', '00010', '00100', '01000', '10000', '11111'],
    97: ['00000', '01110', '00001', '01111', '10001', '10011', '01101'],
    98: ['10000', '10000', '10110', '11001', '10001', '11001', '10110'],
    99: ['00000', '01110', '10000', '10000', '10000', '10001', '01110'],
    100: ['00001', '00001', '01101', '10011', '10001', '10011', '01101'],
    101: ['00000', '01110', '10001', '11111', '10000', '10001', '01110'],
    104: ['10000', '10000', '10110', '11001', '10001', '10001', '10001'],
    108: ['01100', '00100', '00100', '00100', '00100', '00100', '01110'],
    109: ['00000', '11010', '10101', '10101', '10101', '10101', '10101'],
    110: ['00000', '10110', '11001', '10001', '10001', '10001', '10001'],
    111: ['00000', '01110', '10001', '10001', '10001', '10001', '01110'],
    114: ['00000', '10110', '11001', '10000', '10000', '10000', '10000'],
    121: ['00000', '10001', '10001', '01111', '00001', '10001', '01110'],
    122: ['00000', '11111', '00010', '00100', '01000', '10000', '11111'],
  };

  static List<String> forCodeUnit(int codeUnit) {
    return _glyphs[codeUnit] ?? fallback;
  }
}
