import 'package:equatable/equatable.dart';

class PagingEntity extends Equatable {
  final int currentPage;
  final int totalPage;
  final int size;
  final int totalData;

  const PagingEntity({
    required this.currentPage,
    required this.totalPage,
    required this.size,
    required this.totalData,
  });

  @override
  List<Object?> get props => [currentPage, totalPage, size, totalData];
}
