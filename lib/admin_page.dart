import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers cho Bác sĩ
  final _nameController = TextEditingController();
  final _imageLinkController = TextEditingController();

  // Controller cho Chuyên khoa & Bệnh viện
  final _specialityNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();

  String? _selectedHospital; // Sẽ chọn từ Firebase
  String? _selectedDept; // Sẽ chọn từ Firebase
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Nâng lên 4 Tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _imageLinkController.dispose();
    _specialityNameController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  // --- HÀM TỰ ĐỘNG GÁN ICON THEO TÊN ---
  IconData _getIconForSpeciality(String name) {
    name = name.toLowerCase();
    if (name.contains("tim") || name.contains("mạch"))
      return Icons.favorite_rounded;
    if (name.contains("nhi") || name.contains("trẻ"))
      return Icons.child_care_rounded;
    if (name.contains("mắt")) return Icons.visibility_rounded;
    if (name.contains("tâm thần") || name.contains("não"))
      return Icons.psychology_rounded;
    if (name.contains("chỉnh hình") || name.contains("xương"))
      return Icons.healing_rounded;
    if (name.contains("nội")) return Icons.medical_services_rounded;
    if (name.contains("ngoại")) return Icons.biotech_rounded;
    if (name.contains("da liễu")) return Icons.face_retouching_natural_rounded;
    if (name.contains("tai") || name.contains("mũi") || name.contains("họng"))
      return Icons.hearing_rounded;
    if (name.contains("răng") || name.contains("hàm"))
      return Icons.sentiment_satisfied_alt;
    return Icons.label_important_outline;
  }

  // --- HÀM XOÁ CHUNG ---
  Future<void> _deleteItem(String collection, String id, String name) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xoá '$name' thành công!"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi xoá: $e");
    }
  }

  // --- LOGIC LƯU CHUYÊN KHOA ---
  Future<void> _saveSpeciality() async {
    if (_specialityNameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('specialities').add({
        'name': _specialityNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _specialityNameController.clear();
      _showSuccess("Thêm chuyên khoa thành công!");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- LOGIC LƯU BỆNH VIỆN (NEW) ---
  Future<void> _saveHospital() async {
    if (_hospitalNameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('hospitals').add({
        'name': _hospitalNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _hospitalNameController.clear();
      _showSuccess("Thêm bệnh viện thành công!");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- LOGIC LƯU BÁC SĨ ---
  Future<void> _saveDoctor() async {
    if (_nameController.text.isEmpty ||
        _imageLinkController.text.isEmpty ||
        _selectedDept == null ||
        _selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đủ tên, ảnh và CHỌN đủ thông tin!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': _nameController.text.trim(),
        'dept': _selectedDept,
        'hospital': _selectedHospital,
        'image': _imageLinkController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameController.clear();
      _imageLinkController.clear();
      _showSuccess("Thêm bác sĩ thành công! 🔥");
      _tabController.animateTo(1);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Hệ Thống Quản Trị",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: "THÊM BÁC SĨ"),
            Tab(icon: Icon(Icons.list_alt), text: "DANH SÁCH BS"),
            Tab(icon: Icon(Icons.category), text: "CHUYÊN KHOA"),
            Tab(icon: Icon(Icons.local_hospital), text: "BỆNH VIỆN"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddDoctorTab(),
          _buildManageDoctorsTab(),
          _buildSpecialityTab(),
          _buildHospitalTab(),
        ],
      ),
    );
  }

  // --- TAB 1: THÊM BÁC SĨ ---
  Widget _buildAddDoctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProInput(
                "Tên bác sĩ",
                _nameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 15),
              const Text(
                "Chọn Chuyên khoa",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildDynamicDropdown(
                "specialities",
                _selectedDept,
                (val) => setState(() => _selectedDept = val),
              ),
              const SizedBox(height: 15),
              _buildProInput("Link ảnh", _imageLinkController, Icons.link),
              const SizedBox(height: 20),
              const Text(
                "Chọn Bệnh viện",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildDynamicDropdown(
                "hospitals",
                _selectedHospital,
                (val) => setState(() => _selectedHospital = val),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LƯU BÁC SĨ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 2: QUẢN LÝ BÁC SĨ ---
  Widget _buildManageDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snapshot.data!.docs[i];
            String imgPath = doc['image'].toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: imgPath.startsWith('http')
                      ? NetworkImage(imgPath)
                      : AssetImage(imgPath) as ImageProvider,
                ),
                title: Text(
                  doc['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${doc['dept']} - ${doc['hospital']}"),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _confirmDeleteDialog("doctors", doc.id, doc['name']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: QUẢN LÝ CHUYÊN KHOA ---
  Widget _buildSpecialityTab() {
    return _buildCommonTab(
      controller: _specialityNameController,
      hint: "Tên chuyên khoa mới",
      collection: "specialities",
      onSave: _saveSpeciality,
      isSpeciality: true,
    );
  }

  // --- TAB 4: QUẢN LÝ BỆNH VIỆN ---
  Widget _buildHospitalTab() {
    return _buildCommonTab(
      controller: _hospitalNameController,
      hint: "Tên bệnh viện mới",
      collection: "hospitals",
      onSave: _saveHospital,
      isSpeciality: false,
    );
  }

  // Widget dùng chung cho Tab Chuyên khoa và Bệnh viện
  Widget _buildCommonTab({
    required TextEditingController controller,
    required String hint,
    required String collection,
    required VoidCallback onSave,
    required bool isSpeciality,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildProInput(
                  hint,
                  controller,
                  isSpeciality
                      ? Icons.category_outlined
                      : Icons.local_hospital_outlined,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isSaving ? null : onSave,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  minimumSize: const Size(55, 55),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 2),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var item = snapshot.data!.docs[i];
                  String name = item['name'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Icon(
                          isSpeciality
                              ? _getIconForSpeciality(name)
                              : Icons.business_outlined,
                          color: Colors.blue[700],
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _confirmDeleteDialog(collection, item.id, name),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET DROPDOWN ĐỘNG ---
  Widget _buildDynamicDropdown(
    String collection,
    String? value,
    Function(String?) onChanged,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var items = snapshot.data!.docs
            .map((doc) => doc['name'].toString())
            .toList();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text("Bấm để chọn"),
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  void _confirmDeleteDialog(String collection, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xoá?"),
        content: Text(
          "Thắng có chắc muốn xoá '$name' không? Dữ liệu sẽ mất vĩnh viễn.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("HỦY"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteItem(collection, id, name);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              "XOÁ NGAY",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
