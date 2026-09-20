/// SafetyGuard 校验结论（架构 14.3.1）。
sealed class SafetyVerdict {
  const SafetyVerdict();
}

/// 通过，原样放行。
class SafetyPassed extends SafetyVerdict {
  const SafetyPassed();
}

/// 被规则改写（如负荷增幅截断至 10%），返回改写后的内容。
class SafetyRewritten<T> extends SafetyVerdict {
  const SafetyRewritten(this.rewritten, this.reason);

  final T rewritten;
  final String reason;
}

/// 拦截（如伤病动作未替换），要求上游重新生成。
class SafetyBlocked extends SafetyVerdict {
  const SafetyBlocked(this.reason);

  final String reason;
}

/// 单条硬规则。无模型、纯代码，输入输出均为已解析的业务对象。
abstract class SafetyRule<T> {
  const SafetyRule();

  String get name;

  SafetyVerdict check(T input);
}

/// 独立于 LLM 的纯规则安全校验层（ADR-10）。
///
/// 所有涉及身体负荷的输出（训练计划 / 下次建议 / 负荷调整）
/// 必须通过 [SafetyGuard.check] 才能触达用户；
/// LLM 自评的 safety_flag 仅作参考，不具备放行效力。
class SafetyGuard<T> {
  SafetyGuard({required this.rules});

  final List<SafetyRule<T>> rules;

  SafetyVerdict check(T input) {
    for (final rule in rules) {
      final verdict = rule.check(input);
      switch (verdict) {
        case SafetyPassed():
          continue;
        case SafetyRewritten():
          return verdict;
        case SafetyBlocked():
          return verdict; // 首个命中即生效，逐条记录到 event_log 由调用方负责
      }
    }
    return const SafetyPassed();
  }
}
