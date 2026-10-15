// To parse this JSON data, do
//
//     final allUserDataModel = allUserDataModelFromJson(jsonString);

import 'dart:convert';

AllUserDataModel allUserDataModelFromJson(String str) =>
    AllUserDataModel.fromJson(json.decode(str));

String allUserDataModelToJson(AllUserDataModel data) =>
    json.encode(data.toJson());

class AllUserDataModel {
  int? id;
  String? name;
  String? companyName;
  String? mobile;
  String? email;
  String? whatsapp;
  String? area;
  String? photo;
  String? profileType;
  List<UserCategory>? userCategories;
  List<UserSubCategory>? userSubCategories;

  AllUserDataModel({
    this.id,
    this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.whatsapp,
    this.area,
    this.photo,
    this.profileType,
    this.userCategories,
    this.userSubCategories,
  });

  factory AllUserDataModel.fromJson(Map<String, dynamic> json) =>
      AllUserDataModel(
        id: json["id"],
        name: json["name"],
        companyName: json["company_name"],
        mobile: json["mobile"],
        email: json["email"],
        whatsapp: json["whatsapp"],
        area: json["area"],
        photo: json["photo"],
        profileType: json["profile_type"],
        userCategories: json["user_categories"] == null
            ? []
            : List<UserCategory>.from(
                json["user_categories"]!.map((x) => UserCategory.fromJson(x))),
        userSubCategories: json["user_sub_categories"] == null
            ? []
            : List<UserSubCategory>.from(json["user_sub_categories"]!
                .map((x) => UserSubCategory.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "company_name": companyName,
        "mobile": mobile,
        "email": email,
        "whatsapp": whatsapp,
        "area": area,
        "photo": photo,
        "profile_type": profileType,
        "user_categories": userCategories == null
            ? []
            : List<dynamic>.from(userCategories!.map((x) => x.toJson())),
        "user_sub_categories": userSubCategories == null
            ? []
            : List<dynamic>.from(userSubCategories!.map((x) => x.toJson())),
      };
}

class UserCategory {
  int? uId;
  int? id;
  int? uCategoryId;
  Categories? categories;

  UserCategory({
    this.uId,
    this.id,
    this.uCategoryId,
    this.categories,
  });

  factory UserCategory.fromJson(Map<String, dynamic> json) => UserCategory(
        uId: json["u_id"],
        id: json["id"],
        uCategoryId: json["u_catg_id"],
        categories: json["categories"] == null
            ? null
            : Categories.fromJson(json["categories"]),
      );

  Map<String, dynamic> toJson() => {
        "u_id": uId,
        "id": id,
        "u_catg_id": uCategoryId,
        "categories": categories?.toJson(),
      };
}

class Categories {
  int? id;
  String? category;

  Categories({
    this.id,
    this.category,
  });

  factory Categories.fromJson(Map<String, dynamic> json) => Categories(
        id: json["id"],
        category: json["category"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "category": category,
      };
}

class UserSubCategory {
  int? uId;
  int? id;
  int? uSubcatgId;
  SubCategories? subCategories;

  UserSubCategory({
    this.uId,
    this.id,
    this.uSubcatgId,
    this.subCategories,
  });

  factory UserSubCategory.fromJson(Map<String, dynamic> json) =>
      UserSubCategory(
        uId: json["u_id"],
        id: json["id"],
        uSubcatgId: json["u_subcatg_id"],
        subCategories: json["sub_categories"] == null
            ? null
            : SubCategories.fromJson(json["sub_categories"]),
      );

  Map<String, dynamic> toJson() => {
        "u_id": uId,
        "id": id,
        "u_subcatg_id": uSubcatgId,
        "sub_categories": subCategories?.toJson(),
      };
}

class SubCategories {
  int? id;
  String? subcategory;

  SubCategories({
    this.id,
    this.subcategory,
  });

  factory SubCategories.fromJson(Map<String, dynamic> json) => SubCategories(
        id: json["id"],
        subcategory: json["subcategory"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "subcategory": subcategory,
      };
}
