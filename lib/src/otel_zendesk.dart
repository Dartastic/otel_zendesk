// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_zendesk_suppression.dart';

const _tracerName = 'dartastic_otel_libs_zendesk';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps any Zendesk Support API call in a CLIENT span.
Future<T> tracedZendesk<T>({
  required String resource,
  required String action,
  required String subdomain,
  required Future<T> Function() invoke,
  int? ticketId,
  int? userId,
}) async {
  if (zendeskInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'zendesk.resource': resource,
    'zendesk.action': action,
    'zendesk.operation': '$resource.$action',
    'zendesk.subdomain': subdomain,
  };
  if (ticketId != null) m['zendesk.ticket.id'] = ticketId;
  if (userId != null) m['zendesk.user.id'] = userId;

  final span = _tracer().startSpan(
    'zendesk $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
