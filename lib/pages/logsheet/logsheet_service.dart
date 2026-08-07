import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'logsheet_models.dart';

class GoogleSheetsService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      "email",
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/drive",
    ],
  );

  final DatabaseReference _configRef =
      FirebaseDatabase.instance.ref("logsheet_config");

  GoogleSignInAccount? _account;
  Map<String, String>? _authHeaders;

  bool get isSignedIn => _account != null;
  GoogleSignInAccount? get account => _account;

  // ─── Auth ────────────────────────────────────────────────────────────────────

  Future<String?> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      if (_account == null) return "Sign in cancelled";
      _authHeaders = await _account!.authHeaders;
      debugPrint("Google Sign-In success: ${_account!.email}");
      return null;
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _authHeaders = null;
  }

  Future<Map<String, String>> _getHeaders() async {
    if (_authHeaders == null && _account != null) {
      _authHeaders = await _account!.authHeaders;
    }
    return {
      ...?_authHeaders,
      "Content-Type": "application/json",
    };
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Builds a safe URL-encoded range string for use in Google Sheets API URLs.
  ///
  /// Problem: Sheet names that start with a digit (e.g. "2026_06_27") require
  /// single-quote wrapping in A1 notation: '2026_06_27'!A2:BR2
  ///
  /// Problem with Uri.parse(): Dart's Uri.parse() silently strips single quotes
  /// from URL path segments because they are not valid path characters per RFC 3986.
  /// This causes Google API to receive the unquoted name and return 400 INVALID_ARGUMENT.
  ///
  /// Fix: URL-encode only the single quotes as %27. The Google Sheets API server
  /// decodes %27 back to ' before parsing the range notation.
  /// Result: .../values/%272026_06_27%27!A2:BR2  ✅
  String _buildRange(String sheetName, String cellRange) {
    // Encode just the single-quote characters to %27.
    // We wrap the sheet name in single quotes first, then encode the quotes only.
    final encodedSheet = "'$sheetName'".replaceAll("'", "%27");
    return "$encodedSheet!$cellRange";
  }

  /// Shorthand for a full-sheet range reference used in read calls.
  String _sheetRef(String sheetName) {
    return "'$sheetName'".replaceAll("'", "%27");
  }

  /// Converts a 1-based column index to A1-notation letter (e.g. 1→A, 27→AA).
  String _colLetter(int col) {
    String letter = "";
    while (col > 0) {
      col--;
      letter = String.fromCharCode(65 + (col % 26)) + letter;
      col ~/= 26;
    }
    return letter;
  }

  // ─── Spreadsheet management ──────────────────────────────────────────────────

  Future<String?> findOrCreateSpreadsheet(String name) async {
    // Check Firebase cache first
    final snapshot = await _configRef.child(name).get();
    if (snapshot.exists) {
      final id = snapshot.child("spreadsheetId").value as String;
      debugPrint("Found existing spreadsheet in Firebase: $id");
      return id;
    }

    try {
      final headers = await _getHeaders();
      final resp = await http.post(
        Uri.parse("https://sheets.googleapis.com/v4/spreadsheets"),
        headers: headers,
        body: json.encode({
          "properties": {"title": name},
          "sheets": [
            {"properties": {"title": "Sheet1"}}
          ],
        }),
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final spreadsheetId = data["spreadsheetId"] as String;
        await _configRef.child(name).set({
          "spreadsheetId": spreadsheetId,
          "createdBy": _account?.email ?? "",
          "createdAt": ServerValue.timestamp,
        });
        debugPrint("Created new spreadsheet: $name ($spreadsheetId)");
        return spreadsheetId;
      }
      debugPrint("Create spreadsheet failed: ${resp.body}");
    } catch (e) {
      debugPrint("Create spreadsheet error: $e");
    }
    return null;
  }

  // ─── Sheet (tab) management ──────────────────────────────────────────────────

  Future<bool> ensureSheet(
      String spreadsheetId, String sheetName, String area) async {
    final headers = await _getHeaders();

    // Check if sheet tab already exists
    final metaResp = await http.get(
      Uri.parse("https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId"),
      headers: headers,
    );
    if (metaResp.statusCode != 200) return false;

    final data = json.decode(metaResp.body);
    final sheets = data["sheets"] as List;
    for (var sheet in sheets) {
      if (sheet["properties"]["title"] == sheetName) return true;
    }

    // Add the new sheet tab
    final addResp = await http.post(
      // Note: batchUpdate goes on the spreadsheet URL, not /sheets:addBatch
      Uri.parse(
          "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId:batchUpdate"),
      headers: headers,
      body: json.encode({
        "requests": [
          {
            "addSheet": {
              "properties": {"title": sheetName}
            }
          }
        ]
      }),
    );

    if (addResp.statusCode == 200) {
      await _ensureHeaderRow(spreadsheetId, sheetName, area);
      return true;
    }
    debugPrint("addSheet failed: ${addResp.body}");
    return false;
  }

  Future<void> _ensureHeaderRow(
      String spreadsheetId, String sheetName, String area) async {
    final headers = await _getHeaders();

    // FIX: use _buildRange() so date-names like "2026_06_27" become %272026_06_27%27
    final checkRange = _buildRange(sheetName, "A1:ZZ2");
    final checkResp = await http.get(
      Uri.parse(
          "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$checkRange"),
      headers: headers,
    );

    if (checkResp.statusCode == 200) {
      final data = json.decode(checkResp.body);
      if (data["values"] != null && (data["values"] as List).isNotEmpty) {
        return; // Header row already exists
      }
    }

    final groups = area == "boiler" ? boilerGroups : steamTurbineGroups;
    final headerRow = getHeaderRow(groups);
    final boundaryRow = getBoundaryRow(groups);
    final colCount = headerRow.length;

    // FIX: same encoding for write URL
    final writeRange = _buildRange(sheetName, "A1:${_colLetter(colCount)}2");
    await http.put(
      Uri.parse(
              "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$writeRange")
          .replace(queryParameters: {"valueInputOption": "USER_ENTERED"}),
      headers: headers,
      body: json.encode({"values": [headerRow, boundaryRow]}),
    );
  }

  // ─── Data read ───────────────────────────────────────────────────────────────

  Future<List<Map<String, String>>?> getExistingData(
      String spreadsheetId, String sheetName) async {
    final headers = await _getHeaders();

    // FIX: use _sheetRef() for sheet-only reference (no cell range suffix needed)
    final sheetRef = _sheetRef(sheetName);
    final resp = await http.get(
      Uri.parse(
          "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$sheetRef"),
      headers: headers,
    );
    if (resp.statusCode != 200) return null;

    final data = json.decode(resp.body);
    final rows = data["values"] as List?;
    if (rows == null || rows.length < 2) return [];

    final headerRow = (rows[0] as List).cast<String>();
    final List<Map<String, String>> result = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i] as List;
      final Map<String, String> entry = {};
      for (int j = 0; j < row.length && j < headerRow.length; j++) {
        entry[headerRow[j]] = row[j].toString();
      }
      result.add(entry);
    }
    return result;
  }

  // ─── Data write ──────────────────────────────────────────────────────────────

  Future<String?> saveTimeSlot({
    required String spreadsheetId,
    required String sheetName,
    required List<FieldGroup> groups,
    required String timeSlot,
    required String operatorName,
    required int shift,
    required String supervisor,
    required String remark,
    required Map<String, String> fieldValues,
  }) async {
    final headers = await _getHeaders();
    final headerRow = getHeaderRow(groups);

    // Build the row data array
    final List<String> rowData = List.filled(headerRow.length, "");
    rowData[0] = timeSlot;
    rowData[1] = operatorName;
    rowData[2] = shift.toString();
    rowData[3] = supervisor;
    rowData[4] = remark;

    for (var group in groups) {
      for (var field in group.fields) {
        final idx = headerRow.indexOf(getHeaderLabel(field));
        if (idx != -1 && fieldValues.containsKey(field.id)) {
          rowData[idx] = fieldValues[field.id] ?? "";
        }
      }
    }

    int rowNum = 2;

    // Check for existing row with this timeSlot → update in place
    try {
      final existing = await getExistingData(spreadsheetId, sheetName);
      if (existing != null) {
        for (int i = 0; i < existing.length; i++) {
          if (existing[i]["Time"] == timeSlot) {
            rowNum = i + 2;

            // FIX: properly encoded range for update
            final range =
                _buildRange(sheetName, "A$rowNum:${_colLetter(headerRow.length)}$rowNum");
            final resp = await http.put(
              Uri.parse(
                      "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range")
                  .replace(queryParameters: {"valueInputOption": "USER_ENTERED"}),
              headers: headers,
              body: json.encode({"values": [rowData]}),
            );
            if (resp.statusCode == 200) return null;
            return "Update failed: ${resp.body}";
          }
        }
        rowNum = existing.length + 2;
      }
    } catch (e) {
      debugPrint("getExistingData error: $e");
    }

    // FIX: properly encoded range for append
    final range =
        _buildRange(sheetName, "A$rowNum:${_colLetter(headerRow.length)}$rowNum");

    try {
      final resp = await http.put(
        Uri.parse(
                "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range")
            .replace(queryParameters: {"valueInputOption": "USER_ENTERED"}),
        headers: headers,
        body: json.encode({"values": [rowData]}),
      );
      if (resp.statusCode == 200) return null;
      return "Write failed: ${resp.body}";
    } catch (e) {
      return "Network error: $e";
    }
  }
}