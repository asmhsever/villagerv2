class AppRoutes {
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String home = '/';

  static const String adminDashboard = '/admin/dashboard';

  static const String houseDashboard = '/house/dashboard';
  static const String houseComplaintForm = '/house/complaint_form';

  static const String lawDashboard = '/law/dashboard';

  // ✨ Complaint Routes - ใหม่
  static const String complaint = '/law/complaint';
  static const String complaintForm = '/law/complaint/form';
  static const String complaintDetail = '/law/complaint/detail';
  static const String complaintEdit = '/law/complaint/edit';
  static const String complaintDelete = '/law/complaint/delete';

  // ✨ Bill Routes - เปิดใช้งาน
  static const String lawBill = '/law/bill';
  static const String billForm = '/law/bill/form';
  static const String billDetail = '/law/bill/detail';
  static const String billEdit = '/law/bill/edit';

  // ✨ Other Routes - เตรียมไว้
  static const String notion = '/law/notion';
  static const String animal = '/law/animal';
  static const String resident = '/law/resident';
  static const String meeting = '/law/meeting';
  static const String LawProfilePage = '/law/profile';

  static const String notFound = 'not_found';
  static const String splash = 'splash';
}