import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_scanner/mrz_scanner.dart';
import 'camera_view.dart';
import 'mrz_helper.dart';
import 'package:camera/camera.dart';

class MRZScanner extends StatefulWidget {
  const MRZScanner({
    Key? controller,
    required this.onSuccess,
    this.initialDirection = CameraLensDirection.back,
    this.showOverlay = true,
  }) : super(key: controller);
  final Function(ScannedDoc mrzResult) onSuccess;
  final CameraLensDirection initialDirection;
  final bool showOverlay;
  @override
  // ignore: library_private_types_in_public_api
  MRZScannerState createState() => MRZScannerState();
}

class MRZScannerState extends State<MRZScanner> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _canProcess = true;
  bool _isBusy = false;
  List result = [];
  ScannedDoc? _scannedDoc;

  void resetScanning() => _isBusy = false;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MRZCameraView(
      showOverlay: widget.showOverlay,
      initialDirection: widget.initialDirection,
      onImage: _processImage,
    );
  }

  void _parseScannedText(List<String> lines, var filePath) {
    try {
      final data = MRZParser.parse(lines);
      _isBusy = true;
      _scannedDoc = ScannedDoc(result: data, filePath: filePath);
      widget.onSuccess(_scannedDoc!);
    } catch (e) {
      _scannedDoc = null;
      _isBusy = false;
    }
  }

  Future<void> _processImage(
      InputImage inputImage, CameraController controller) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final recognizedText = await _textRecognizer.processImage(inputImage);
    String fullText = recognizedText.text;
    String trimmedText = fullText.replaceAll(' ', '');
    List allText = trimmedText.split('\n');

    List<String> ableToScanText = [];
    for (var e in allText) {
      if (MRZHelper.testTextLine(e).isNotEmpty) {
        ableToScanText.add(MRZHelper.testTextLine(e));
      }
    }
    List<String>? result = MRZHelper.getFinalListToParse([...ableToScanText]);

    if (result != null) {
      var filePath = await controller.takePicture();
      _parseScannedText([...result], filePath);
    } else {
      _isBusy = false;
    }
  }
}

class ScannedDoc {
  MRZResult result;
  var filePath;

  ScannedDoc({
    required this.result,
    required this.filePath,
  });
}
