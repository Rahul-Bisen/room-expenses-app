import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  // Railway deployed URL — set to null to use localhost for local dev
  static const String? _deployedUrl = 'https://room-expenses-backend-production.up.railway.app/api';
  // static const String? _deployedUrl = null; // local dev

  static String get _baseUrl =>
      _deployedUrl ?? (kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api');

  static String get baseUrl => _baseUrl;

  Future<MonthlyResponse> getMonth(String month) async {
    final resp = await http.get(Uri.parse('$_baseUrl/month/${Uri.encodeComponent(month)}'));
    if (resp.statusCode == 200) {
      return MonthlyResponse.fromJson(json.decode(resp.body));
    }
    throw Exception('Failed to load month data: ${resp.statusCode}');
  }

  Future<MonthlyExpenseItem> addExpense(String month, Map<String, dynamic> expense) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/expenses/${Uri.encodeComponent(month)}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(expense),
    );
    if (resp.statusCode == 200) {
      return MonthlyExpenseItem.fromJson(json.decode(resp.body));
    }
    throw Exception('Failed to add expense: ${resp.statusCode} ${resp.body}');
  }

  Future<MonthlyTransaction> addTransaction(String month, Map<String, dynamic> transaction) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/transactions/${Uri.encodeComponent(month)}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction),
    );
    if (resp.statusCode == 200) {
      return MonthlyTransaction.fromJson(json.decode(resp.body));
    }
    throw Exception('Failed to add transaction: ${resp.statusCode}');
  }

  Future<void> updateExpense(String month, int expenseId, Map<String, dynamic> expense) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/expenses/${Uri.encodeComponent(month)}/$expenseId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(expense),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to update expense: ${resp.statusCode}');
    }
  }

  Future<void> deleteExpense(String month, int expenseId) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/expenses/${Uri.encodeComponent(month)}/$expenseId'),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete expense: ${resp.statusCode}');
    }
  }

  Future<void> deleteTransactions(List<int> ids) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ids),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete transactions: ${resp.statusCode}');
    }
  }

  Future<void> updateTransaction(String month, int transactionId, Map<String, dynamic> transaction) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/transactions/${Uri.encodeComponent(month)}/$transactionId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to update transaction: ${resp.statusCode}');
    }
  }

  Future<MonthMemberInfo> addMonthMember(String month, String name) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/month/${Uri.encodeComponent(month)}/members'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (resp.statusCode == 200) {
      return MonthMemberInfo.fromJson(json.decode(resp.body));
    }
    throw Exception('Failed to add member: ${resp.statusCode}');
  }

  Future<void> updateMemberStatus(String month, String memberName, bool active) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/month/${Uri.encodeComponent(month)}/members/${Uri.encodeComponent(memberName)}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'active': active}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to update member status: ${resp.statusCode}');
    }
  }

  Future<void> deleteMember(String month, String memberName) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/month/${Uri.encodeComponent(month)}/members/${Uri.encodeComponent(memberName)}'),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete member: ${resp.statusCode}');
    }
  }
}
