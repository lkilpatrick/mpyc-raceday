/// Abstract interface for firing race signals.
///
/// Implementations control how signals are physically fired:
/// - [ManualSignalController]: Operator confirms signals were fired manually
/// - [BluetoothSignalController]: Future BLE integration for Otter Box hardware
///
/// Each method returns the exact timestamp when the signal was confirmed/fired.
abstract class SignalController {
  /// Fire the warning signal (class flag up). Called at T-5:00.
  Future<DateTime> fireWarningSignal();

  /// Fire the preparatory signal (P/I/Z/U flag up). Called at T-4:00.
  Future<DateTime> firePreparatorySignal();

  /// Remove the preparatory signal. Called at T-1:00.
  Future<DateTime> removePreparatorySignal();

  /// Fire the starting signal (all flags down). Called at T-0:00.
  Future<DateTime> fireStartSignal();

  /// Fire a general recall signal. Resets the sequence.
  Future<DateTime> fireRecallSignal();

  /// Fire an individual recall signal (X flag). Does not stop sequence.
  Future<DateTime> fireIndividualRecallSignal();

  /// Signal a postponement (AP flag).
  Future<DateTime> firePostponeSignal();

  /// Dispose of any resources.
  void dispose();
}

/// Manual signal controller — logs signals when operator confirms
/// they've been fired physically (horn, flags, etc.).
class ManualSignalController implements SignalController {
  @override
  Future<DateTime> fireWarningSignal() async => DateTime.now();

  @override
  Future<DateTime> firePreparatorySignal() async => DateTime.now();

  @override
  Future<DateTime> removePreparatorySignal() async => DateTime.now();

  @override
  Future<DateTime> fireStartSignal() async => DateTime.now();

  @override
  Future<DateTime> fireRecallSignal() async => DateTime.now();

  @override
  Future<DateTime> fireIndividualRecallSignal() async => DateTime.now();

  @override
  Future<DateTime> firePostponeSignal() async => DateTime.now();

  @override
  void dispose() {}
}

/// Placeholder for future Otter Box BLE integration.
///
/// To implement:
/// 1. Discover and connect to Otter Box device via BLE
/// 2. Map each signal method to the appropriate BLE characteristic write
/// 3. Wait for acknowledgment from the device before returning timestamp
/// 4. Handle connection loss gracefully (fall back to manual)
///
/// Expected BLE protocol (to be defined with hardware team):
/// - Service UUID: TBD
/// - Signal characteristic UUID: TBD
/// - Write values: 0x01=warning, 0x02=prep, 0x03=prepRemove,
///   0x04=start, 0x05=recall, 0x06=individualRecall, 0x07=postpone
/// - Read acknowledgment: 0x00=success, 0x01=failure
class BluetoothSignalController implements SignalController {
  // final BluetoothDevice? _device;
  // final BluetoothCharacteristic? _signalCharacteristic;

  @override
  Future<DateTime> fireWarningSignal() async {
    // TODO: Write 0x01 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> firePreparatorySignal() async {
    // TODO: Write 0x02 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> removePreparatorySignal() async {
    // TODO: Write 0x03 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> fireStartSignal() async {
    // TODO: Write 0x04 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> fireRecallSignal() async {
    // TODO: Write 0x05 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> fireIndividualRecallSignal() async {
    // TODO: Write 0x06 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  Future<DateTime> firePostponeSignal() async {
    // TODO: Write 0x07 to signal characteristic, await ack
    return DateTime.now();
  }

  @override
  void dispose() {
    // TODO: Disconnect BLE device
  }
}
