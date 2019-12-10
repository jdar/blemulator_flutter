import 'dart:async';
import 'package:blemulator_example/adapter/ble_adapter.dart';
import 'package:blemulator_example/scan/scan_result.dart';
import 'package:blemulator_example/scan/scan_result_view_model.dart';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class ScanBloc
    extends Bloc<ScanEvent, ScanState> {
  BleAdapter _bleAdapter;
  StreamSubscription _scanResultsSubscription;

  ScanBloc(this._bleAdapter);

  @override
  ScanState get initialState => ScanState.initial();

  @override
  Stream<ScanState> mapEventToState(
    ScanEvent event,
  ) async* {
    if (event is StartScan) {
      yield* _mapStartScanToState(event);
    } else if (event is StopScan) {
      yield* _mapStopScanToState(event);
    } else if (event is NewScanResult) {
      yield* _mapNewScanResultToState(event);
    }
  }

  Stream<ScanState> _mapStartScanToState(
      StartScan event) async* {
    _cancelScanResultsSubscription();
    _scanResultsSubscription =
        _bleAdapter.startPeripheralScan().listen((ScanResult scanResult) {
      add(NewScanResult(scanResult));
    });
    yield ScanState(
        scanResults: state.scanResults, scanningEnabled: true);
  }

  Stream<ScanState> _mapStopScanToState(
      StopScan event) async* {
    _cancelScanResultsSubscription();
    await _bleAdapter.stopPeripheralScan();
    yield ScanState(
        scanResults: state.scanResults, scanningEnabled: false);
  }

  Stream<ScanState> _mapNewScanResultToState(
      NewScanResult event) async* {
    Map<String, ScanResultViewModel> updatedScanResults = state.scanResults;
    String identifier = event.scanResult.identifier;

    if (updatedScanResults.containsKey(identifier)) {
      if (updatedScanResults[identifier] != event.scanResult) {
        updatedScanResults = Map.from(state.scanResults);
        updatedScanResults[identifier] = event.scanResult.viewModel();
      }
    } else {
      updatedScanResults = Map.from(state.scanResults);
      updatedScanResults.addEntries([MapEntry(identifier, event.scanResult.viewModel())]);
    }
    yield ScanState(
        scanResults: updatedScanResults,
        scanningEnabled: state.scanningEnabled);
  }

  void _cancelScanResultsSubscription() async {
    if (_scanResultsSubscription != null) {
      await _scanResultsSubscription.cancel();
    }
  }

  @override
  Future<void> close() {
    _cancelScanResultsSubscription();
    return super.close();
  }
}