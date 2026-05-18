// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_zendesk/otel_zendesk.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_zendesk-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('tickets.create records CLIENT span', () async {
    await tracedZendesk<String>(
      resource: 'tickets',
      action: 'create',
      subdomain: 'acme',
      ticketId: 99,
      userId: 7,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('zendesk tickets.create')!);
    expect(a['zendesk.resource'], 'tickets');
    expect(a['zendesk.action'], 'create');
    expect(a['zendesk.operation'], 'tickets.create');
    expect(a['zendesk.subdomain'], 'acme');
    expect(a['zendesk.ticket.id'], 99);
    expect(a['zendesk.user.id'], 7);
  });

  test('suppression skips spans', () async {
    await runWithoutZendeskInstrumentationAsync(() async {
      await tracedZendesk<String>(
        resource: 'tickets',
        action: 'create',
        subdomain: 's',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('zendesk '), isEmpty);
  });
}
