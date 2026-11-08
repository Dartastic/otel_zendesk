// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_zendesk/otel_zendesk.dart';

/// Traces Zendesk calls with OpenTelemetry.
///
/// `otel_zendesk` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Zendesk call in
/// [tracedZendesk]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'zendesk-example');

  // Wraps any Zendesk Support API call in a CLIENT span.
  final zendeskId = await tracedZendesk<String>(
    resource: 'Order',
    action: 'example',
    subdomain: 'example',
    ticketId: 1,
    userId: 1,
    invoke: () async {
      // Make the Zendesk call here, then report what it returned.
      return 'zendesk_8f3a2c';
    },
  );
  OTelLog.info('tracedZendesk returned $zendeskId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutZendeskInstrumentationAsync.
  await runWithoutZendeskInstrumentationAsync(
    () => tracedZendesk<String>(
      resource: 'Order',
      action: 'example',
      subdomain: 'example',
      ticketId: 1,
      userId: 1,
      invoke: () async {
        return 'zendesk_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
