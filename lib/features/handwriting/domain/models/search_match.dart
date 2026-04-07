import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SearchMatch extends Equatable {
  const SearchMatch({
    required this.query,
    required this.matchedText,
    required this.pageId,
    required this.strokeIds,
    required this.boundingBox,
    this.confidence = 1.0,
    this.contextSnippet = '',
  });

  final String query;
  final String matchedText;
  final String pageId;
  final List<String> strokeIds;
  final Rect boundingBox;
  final double confidence;
  final String contextSnippet;

  @override
  List<Object?> get props => [query, matchedText, pageId, strokeIds, boundingBox, confidence, contextSnippet];
}
