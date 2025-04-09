class ApiResponse<T> {
  final String status;
  final String code;
  final String? message;
  final T data;

  ApiResponse({
    required this.status,
    required this.code,
    this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return ApiResponse(
      status: json['status'] as String,
      code: json['code'] as String,
      message: json['message'] as String?,
      data: fromJsonT(json['data'] as Map<String, dynamic>),
    );
  }

  bool get isSuccess => status == "OK" && code == "SUCCESS";
}
