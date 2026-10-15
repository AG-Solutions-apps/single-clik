import 'dart:convert';

OnBoardModel onboardModelFromJson(String str) =>
    OnBoardModel.fromJson(json.decode(str));

String onboardModelToJson(OnBoardModel data) => json.encode(data.toJson());

class OnBoardModel {
  int? code;
  Categories? categories;
  List<OnBoardData>? data;

  OnBoardModel({
    this.code,
    this.categories,
    this.data,
  });

  OnBoardModel copyWith({
    int? code,
    Categories? categories,
    List<OnBoardData>? data,
  }) =>
      OnBoardModel(
        code: code ?? this.code,
        categories: categories ?? this.categories,
        data: data ?? this.data,
      );

  factory OnBoardModel.fromJson(Map<String, dynamic> json) => OnBoardModel(
        code: json["code"],
        categories: json["categories"] == null
            ? null
            : Categories.fromJson(json["categories"]),
        data: json["data"] == null
            ? []
            : List<OnBoardData>.from(
                json["data"]!.map((x) => OnBoardData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "categories": categories?.toJson(),
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class Categories {
  String? category;
  String? categoryImage;

  Categories({
    this.category,
    this.categoryImage,
  });

  Categories copyWith({
    String? category,
    String? categoryImage,
  }) =>
      Categories(
        category: category ?? this.category,
        categoryImage: categoryImage ?? this.categoryImage,
      );

  factory Categories.fromJson(Map<String, dynamic> json) => Categories(
        category: json["category"],
        categoryImage: json["category_image"],
      );

  Map<String, dynamic> toJson() => {
        "category": category,
        "category_image": categoryImage,
      };
}

class OnBoardData {
  String? name;
  String? photo;

  OnBoardData({
    this.name,
    this.photo,
  });

  OnBoardData copyWith({
    String? name,
    String? photo,
  }) =>
      OnBoardData(
        name: name ?? this.name,
        photo: photo ?? this.photo,
      );

  factory OnBoardData.fromJson(Map<String, dynamic> json) => OnBoardData(
        name: json["name"],
        photo: json["photo"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "photo": photo,
      };
}
