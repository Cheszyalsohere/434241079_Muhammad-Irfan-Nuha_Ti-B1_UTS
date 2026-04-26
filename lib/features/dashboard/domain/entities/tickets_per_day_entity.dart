/// Single bucket in the 7-day "tickets created per day" trend.
///
/// One row per calendar date (in the device's local time zone). The
/// data layer fills in zeros for days without activity so the line
/// chart on the dashboard always plots a contiguous 7-point series.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tickets_per_day_entity.freezed.dart';

@freezed
class TicketsPerDay with _$TicketsPerDay {
  const factory TicketsPerDay({
    required DateTime date,
    required int count,
  }) = _TicketsPerDay;
}
