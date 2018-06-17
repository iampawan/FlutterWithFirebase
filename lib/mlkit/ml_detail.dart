import 'package:flutfire/mlkit/ml_home.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlkit/mlkit.dart';

class MLDetail extends StatefulWidget {
  final File _file;
  final String _scannerType;

  MLDetail(this._file, this._scannerType);

  @override
  State<StatefulWidget> createState() {
    return _MLDetailState();
  }
}

class _MLDetailState extends State<MLDetail> {
  FirebaseVisionTextDetector textDetector = FirebaseVisionTextDetector.instance;
  FirebaseVisionBarcodeDetector barcodeDetector =
      FirebaseVisionBarcodeDetector.instance;
  FirebaseVisionLabelDetector labelDetector =
      FirebaseVisionLabelDetector.instance;
  FirebaseVisionFaceDetector faceDetector = FirebaseVisionFaceDetector.instance;
  List<VisionText> _currentTextLabels = <VisionText>[];
  List<VisionBarcode> _currentBarcodeLabels = <VisionBarcode>[];
  List<VisionLabel> _currentLabelLabels = <VisionLabel>[];
  List<VisionFace> _currentFaceLabels = <VisionFace>[];

  Stream sub;
  StreamSubscription<dynamic> subscription;

  @override
  void initState() {
    super.initState();
    sub = new Stream.empty();
    subscription = sub.listen((_) => _getImageSize)..onDone(analyzeLabels);
  }

  void analyzeLabels() async {
    try {
      var currentLabels;
      if (widget._scannerType == TEXT_SCANNER) {
        currentLabels = await textDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentTextLabels = currentLabels;
          });
        }
      } else if (widget._scannerType == BARCODE_SCANNER) {
        currentLabels = await barcodeDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentBarcodeLabels = currentLabels;
          });
        }
      } else if (widget._scannerType == LABEL_SCANNER) {
        currentLabels = await labelDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentLabelLabels = currentLabels;
          });
        }
      } else if (widget._scannerType == FACE_SCANNER) {
        currentLabels = await faceDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentFaceLabels = currentLabels;
          });
        }
      }
    } catch (e) {
      print("MyEx: " + e.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget._scannerType),
        ),
        body: Column(
          children: <Widget>[
            buildImage(context),
            widget._scannerType == TEXT_SCANNER
                ? buildTextList(_currentTextLabels)
                : widget._scannerType == BARCODE_SCANNER
                    ? buildBarcodeList<VisionBarcode>(_currentBarcodeLabels)
                    : widget._scannerType == FACE_SCANNER
                        ? buildBarcodeList<VisionFace>(_currentFaceLabels)
                        : buildBarcodeList<VisionLabel>(_currentLabelLabels)
          ],
        ));
  }

  Widget buildImage(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(
            child: widget._file == null
                ? Text('No Image')
                : FutureBuilder<Size>(
                    future: _getImageSize(
                        Image.file(widget._file, fit: BoxFit.fitWidth)),
                    builder:
                        (BuildContext context, AsyncSnapshot<Size> snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                            foregroundDecoration: (widget._scannerType ==
                                    TEXT_SCANNER)
                                ? TextDetectDecoration(
                                    _currentTextLabels, snapshot.data)
                                : (widget._scannerType == FACE_SCANNER)
                                    ? FaceDetectDecoration(
                                        _currentFaceLabels, snapshot.data)
                                    : (widget._scannerType == BARCODE_SCANNER)
                                        ? BarcodeDetectDecoration(
                                            _currentBarcodeLabels,
                                            snapshot.data)
                                        : LabelDetectDecoration(
                                            _currentLabelLabels, snapshot.data),
                            child:
                                Image.file(widget._file, fit: BoxFit.fitWidth));
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
          )),
    );
  }

  Widget buildBarcodeList<T>(List<T> barcodes) {
    if (barcodes.length == 0) {
      return Expanded(
        flex: 1,
        child: Center(
          child: Text('Nothing detected',
              style: Theme.of(context).textTheme.subhead),
        ),
      );
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: barcodes.length,
            itemBuilder: (context, i) {
              var text;

              final barcode = barcodes[i];
              switch (widget._scannerType) {
                case BARCODE_SCANNER:
                  VisionBarcode res = barcode as VisionBarcode;
                  text = "Raw Value: ${res.rawValue}";
                  break;
                case FACE_SCANNER:
                  VisionFace res = barcode as VisionFace;
                  text =
                      "Raw Value: ${res.smilingProbability},${res.trackingID}";
                  break;
                case LABEL_SCANNER:
                  VisionLabel res = barcode as VisionLabel;
                  text = "Raw Value: ${res.label}";
                  break;
              }

              return _buildTextRow(text);
            }),
      ),
    );
  }

  Widget buildTextList(List<VisionText> texts) {
    if (texts.length == 0) {
      return Expanded(
          flex: 1,
          child: Center(
            child: Text('No text detected',
                style: Theme.of(context).textTheme.subhead),
          ));
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: texts.length,
            itemBuilder: (context, i) {
              return _buildTextRow(texts[i].text);
            }),
      ),
    );
  }

  Widget _buildTextRow(text) {
    return ListTile(
      title: Text(
        "$text",
      ),
      dense: true,
    );
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble())));
    return completer.future;
  }
}

/*
  This code uses the example from azihsoyn/flutter_mlkit
  https://github.com/azihsoyn/flutter_mlkit/blob/master/example/lib/main.dart
*/

class BarcodeDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionBarcode> _barcodes;

  BarcodeDetectDecoration(List<VisionBarcode> barcodes, Size originalImageSize)
      : _barcodes = barcodes,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _BarcodeDetectPainter(_barcodes, _originalImageSize);
  }
}

class _BarcodeDetectPainter extends BoxPainter {
  final List<VisionBarcode> _barcodes;
  final Size _originalImageSize;
  _BarcodeDetectPainter(barcodes, originalImageSize)
      : _barcodes = barcodes,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var barcode in _barcodes) {
      final _rect = Rect.fromLTRB(
          offset.dx + barcode.rect.left / _widthRatio,
          offset.dy + barcode.rect.top / _heightRatio,
          offset.dx + barcode.rect.right / _widthRatio,
          offset.dy + barcode.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}

class TextDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionText> _texts;
  TextDetectDecoration(List<VisionText> texts, Size originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _TextDetectPainter(_texts, _originalImageSize);
  }
}

class _TextDetectPainter extends BoxPainter {
  final List<VisionText> _texts;
  final Size _originalImageSize;
  _TextDetectPainter(texts, originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var text in _texts) {
      final _rect = Rect.fromLTRB(
          offset.dx + text.rect.left / _widthRatio,
          offset.dy + text.rect.top / _heightRatio,
          offset.dx + text.rect.right / _widthRatio,
          offset.dy + text.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}

class FaceDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionFace> _faces;
  FaceDetectDecoration(List<VisionFace> faces, Size originalImageSize)
      : _faces = faces,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _FaceDetectPainter(_faces, _originalImageSize);
  }
}

class _FaceDetectPainter extends BoxPainter {
  final List<VisionFace> _faces;
  final Size _originalImageSize;
  _FaceDetectPainter(faces, originalImageSize)
      : _faces = faces,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var face in _faces) {
      final _rect = Rect.fromLTRB(
          offset.dx + face.rect.left / _widthRatio,
          offset.dy + face.rect.top / _heightRatio,
          offset.dx + face.rect.right / _widthRatio,
          offset.dy + face.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}

class LabelDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionLabel> _labels;
  LabelDetectDecoration(List<VisionLabel> labels, Size originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _LabelDetectPainter(_labels, _originalImageSize);
  }
}

class _LabelDetectPainter extends BoxPainter {
  final List<VisionLabel> _labels;
  final Size _originalImageSize;
  _LabelDetectPainter(labels, originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var label in _labels) {
      final _rect = Rect.fromLTRB(
          offset.dx + label.rect.left / _widthRatio,
          offset.dy + label.rect.top / _heightRatio,
          offset.dx + label.rect.right / _widthRatio,
          offset.dy + label.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}
