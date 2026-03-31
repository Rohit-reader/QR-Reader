import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String name;
  final List<QueryDocumentSnapshot> yarnDocs;

  CompanyModel({
    required this.name,
    required this.yarnDocs,
  });

  int get count => yarnDocs.length;
}