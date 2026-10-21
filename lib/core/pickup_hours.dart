/// Real-time open / break / closed for Didar pickup point.
enum PickupOpenState { open, breakTime, closed }

class PickupHours {
  static PickupOpenState stateNow([DateTime? now]) {
    final n = now ?? DateTime.now();
    // Sunday closed
    if (n.weekday == DateTime.sunday) return PickupOpenState.closed;
    final minutes = n.hour * 60 + n.minute;
    const open = 8 * 60;
    const breakStart = 12 * 60;
    const breakEnd = 13 * 60;
    const close = 18 * 60;
    if (minutes < open || minutes >= close) return PickupOpenState.closed;
    if (minutes >= breakStart && minutes < breakEnd) {
      return PickupOpenState.breakTime;
    }
    return PickupOpenState.open;
  }

  static String labelRu(PickupOpenState s) => switch (s) {
        PickupOpenState.open => 'Открыто',
        PickupOpenState.breakTime => 'Перерыв',
        PickupOpenState.closed => 'Закрыто',
      };

  static String scheduleTextRu =
      'Пн–Сб: 08:00–18:00\nОбед: 12:00–13:00\nВс: выходной';
}
