import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class DoctorImageViewer extends StatelessWidget {
  const DoctorImageViewer({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
          errorWidget: (_, __, ___) => const Text(
            'Unable to load this image',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class DoctorPdfViewer extends StatelessWidget {
  const DoctorPdfViewer({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      appBar: AppBar(
        title: Text(title ?? 'PDF'),
        backgroundColor: DoctorUi.scaffoldBg,
      ),
      body: FutureBuilder<PDFDocument>(
        future: PDFDocument.fromURL(url),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const DoctorEmptyState(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Unable to open PDF',
              message: 'The file could not be loaded. Try again later.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.2),
            );
          }
          return PDFViewer(
            document: snapshot.data!,
            lazyLoad: false,
            showPicker: false,
          );
        },
      ),
    );
  }
}
