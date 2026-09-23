import 'package:isar/isar.dart';
import 'model/expense_model.dart';

class ExpenseService {
  // جلب كافة المصاريف محلياً من قاعدة بيانات Isar
  Future<List<ExpenseModel>> getExpenses() async {
    final isar = Isar.getInstance();
    if (isar == null) return [];
    
    return await isar.expenseModels.where().findAll();
  }

  // حفظ أو إنشاء مصروف جديد محلياً في Isar
  Future<bool> createExpense(ExpenseModel expense) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.expenseModels.put(expense);
      });
      return true;
    } catch (e) {
      print('Error creating local expense: $e');
      return false;
    }
  }

  // تعديل مصروف موجود محلياً في Isar
  Future<bool> updateExpense(int id, ExpenseModel expense) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      expense.id = id;
      await isar.writeTxn(() async {
        await isar.expenseModels.put(expense);
      });
      return true;
    } catch (e) {
      print('Error updating local expense: $e');
      return false;
    }
  }

  // حذف مصروف محلياً من Isar بناءً على المعرف
  Future<bool> deleteExpense(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.expenseModels.delete(id);
      });
      return true;
    } catch (e) {
      print('Error deleting local expense: $e');
      return false;
    }
  }
}