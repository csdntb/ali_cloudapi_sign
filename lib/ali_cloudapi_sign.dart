library ali_cloudapi_sign;

import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// 阿里网关签名算法文档 https://help.aliyun.com/document_detail/29475.html
class AliSign {
  static const String CLOUDAPI_LF = "\n";
  static String gatewayAppkey = "";
  static String gatewayAppsecret = "";
  static List<String> gatewayHosts = [];
  static String gatewayStage = "";

  static Map<String, String> creatAliGatewaySign(String method, Uri uri,
      [Map<String, String> queryParameters]) {
    if (gatewayAppkey.isEmpty ||
        gatewayAppsecret.isEmpty ||
        gatewayHosts.length == 0) {
      throw Exception(
          "pls specify gatewayAppkey/gatewayAppsecret/gatewayHosts");
    }
    var params = Map<String, String>.from(uri.queryParameters);
    if (null != queryParameters) {
      params.addAll(queryParameters);
    }

    params =
        new SplayTreeMap<String, String>.from(params, (a, b) => a.compareTo(b));

    Map<String, String> headerParams = new Map<String, String>();
    headerParams.putIfAbsent("x-ca-key", () => gatewayAppkey);
    headerParams.putIfAbsent("accept", () => "application/json");
    if (method.toUpperCase() == "POST")
      headerParams.putIfAbsent(
          "content-type", () => "application/json; charset=utf-8");
    var time = new DateTime.now().millisecondsSinceEpoch;
    headerParams.putIfAbsent("x-ca-timestamp", () => time.toString());
    StringBuffer sb = new StringBuffer();

    sb.write(method.toUpperCase() + CLOUDAPI_LF);
    List<String> keys = ["accept", "content-md5", "content-type", "date"];
    keys.forEach((element) {
      if (headerParams.containsKey(element)) {
        sb.write(headerParams[element]);
      }
      sb.write(CLOUDAPI_LF);
    });

    sb.write(("x-ca-key") + (':') + (gatewayAppkey) + (CLOUDAPI_LF));
    sb.write(("x-ca-timestamp") +
        (':') +
        (headerParams["x-ca-timestamp"]) +
        (CLOUDAPI_LF));
    sb.write(uri.path);

    if (null != params && params.length > 0) {
      String queryString =
          Uri(queryParameters: new Map<String, dynamic>.from(params)).query;
      sb.write("?$queryString");
    }

    headerParams.putIfAbsent(
        "x-ca-signature-headers", () => "x-ca-timestamp,x-ca-key");
    print("aliSign==${sb.toString()}");
    headerParams = aliSign(sb, headerParams);
    return headerParams;
  }

  static Map<dynamic, dynamic> aliSign(
      StringBuffer string, Map<dynamic, dynamic> headerParams) {
    var key = utf8.encode(gatewayAppsecret);
    var bytes = utf8.encode(string.toString());
    var hmacSha256 = new Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    String sign = base64Encode(digest.bytes);
    headerParams.putIfAbsent("x-ca-signature", () => sign);
    //是否正式环境
    if (gatewayStage.length > 0) {
      headerParams.putIfAbsent(
          "X-Ca-Stage", () => gatewayStage.toUpperCase()); // TEST 测试 // PRE 预发布
    }
    return headerParams;
  }
}
